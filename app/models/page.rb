require 'aasm'
require 's3'
require 'slack_helper'

class Page < ActiveRecord::Base
  include AASM
  include StorageCalculateable

  belongs_to :document
  has_many :locations, dependent: :destroy, as: :locationable

  #s3_object_key is the final cropped image that is used for the page (once filters are applied and cropping is done - refer DOC-141)
  #original_s3_object_key is the original image taken when image is captured (refer to DOC-140)
  validates :s3_object_key, :original_s3_object_key, :presence => true, :uniqueness => true, :if => :uploaded?

  validates :document_id, presence: true
  validates :page_num, presence: true
  validates :page_num, numericality: { only_integer: true, greater_than: 0 }

  attr_accessor :encryption_key

  default_scope { order(page_num: :asc) }
  after_destroy :delete_s3_object

  scope :not_uploaded, -> { where.not(state: :uploaded) }

  aasm column: :state do
    state :pending, :initial => true
    state :uploading
    state :uploaded

    event :start_upload do
      transitions from: [:pending, :uploading], to: :uploading, guard: :files_md5_exists?
    end

    event :complete_upload, :after => :update_storage_size_from_s3 do
      transitions from: [:pending, :uploading], to: :uploaded, guard: [:s3_object_exists?, :files_md5_exists?] #UseCase for Pending => Uploaded transition: When user on phone kills the app right after it has created pages (pending state) but not yet made the next api call to mark the state as "uploading"
    end

    event :reupload, :after => :cleanup_s3_objects do
      transitions from: [:uploaded, :uploading], to: :uploading, guard: :files_md5_exists?
    end
  end

  # delegate Document's document_owners to Page
  # used for StorageCalculateable
  def document_owners
    self.document.document_owners
  end

  def recreate_document_pdf
    #####The call below is a bit low level but since we process creation of PDF in a separate background server, we should commit transactions before enqueueing
    ActiveRecord::Base.connection.commit_db_transaction unless Rails.env.test? || Rails.env.development?

    Resque.enqueue ConvertDocumentPagesToPdfJob, self.document_id
  end

  def files_md5_matched?(original_md5, final_md5)
    return false unless files_md5_exists?
    return false unless original_md5.present? && final_md5.present?
    return self.original_file_md5 == original_md5 && self.final_file_md5 == final_md5
  end

  def files_md5_exists?
    self.original_file_md5.present? && self.final_file_md5.present?
  end

  def s3_object_exists?
    return false if self.s3_object_key.blank? || self.original_s3_object_key.blank?

    bucket = Aws::S3::Bucket.new(ENV['DEFAULT_BUCKET'])

    obj1 = bucket.objects({
      max_keys: 1,
      prefix: self.s3_object_key
    }).first

    obj2 = bucket.objects({
      max_keys: 1,
      prefix: self.original_s3_object_key
    }).first

    return obj1.present? && obj2.present?
  end

  def uploader
    @uploader ||= self.document.uploader
  end

  def reupload
    self.s3_object_key = nil
    self.original_s3_object_key = nil
    self.reupload!
  end

  def delete_s3_object
    DeleteS3ObjectJob.perform_later(self.s3_object_key) unless self.s3_object_key.blank?
    DeleteS3ObjectJob.perform_later(self.original_s3_object_key) unless self.original_s3_object_key.blank?
  end

  def cleanup_s3_objects
    #Don't delete s3 objects from S3. We use the same object name for reupload. So deleting it could cause race conditions. Reupload just overwrites the old object
    self.s3_object_key = nil
    self.original_s3_object_key = nil
  end

  # Update the storage size with actual size on S3
  def update_storage_size_from_s3
    FetchS3ObjectLengthJob.perform_later(self.class.to_s, self.id)
  end

  # This method will be called from FetchS3ObjectLengthJob
  def perform_update_storage_size_from_s3
    total_size = 0
    total_size += fetch_object_size(self.s3_object_key)
    total_size += fetch_object_size(self.original_s3_object_key)

    self.update_column(:storage_size, total_size)
    recalculate_storage_size
  end

  def update_document_initial_pages_completion
    self.document.update_initial_pages_completion if self.document #Possible that document got deleted
  end

  def create_notification_for_completed_page!(current_user)
    return unless self.document.initial_pages_completed?
    if version.to_i > 0
      notify_updated_page_to_connected_users!(current_user)
    else
      notify_new_page_to_connected_users!(current_user)
    end
  end

  def proccess_completion_from_sns_notification(object_key)
    return false if self.uploaded?

    if object_key.match("Page-original-")
      self.update_column(:original_s3_object_key, object_key)
    elsif object_key.match("Page-cropped-")
      self.update_column(:s3_object_key, object_key)
    end

    return false unless self.original_s3_object_key.present? && self.s3_object_key.present?

    errors = []
    begin
      if self.complete_upload!
        self.update_document_initial_pages_completion
        self.recreate_document_pdf
        if self.document.initial_pages_completed?
          DocumentCacheService.update_cache([:document], self.document.consumer_ids_for_owners)
        end
      else
        errors << self.errors.full_messages
      end

    rescue AASM::InvalidTransition => e
      errors << e.message
    end

    unless errors.empty?
      msg = errors.flatten.join(", ")
      SlackHelper.ping({ channel: "#errors", username: "CompleteUploadBot", message: "Page: #{self.id} - #{msg}" })
    end

    return errors.empty?
  end

  private

  def notify_new_page_to_connected_users!(current_user)
    self.document.all_sharees_ids.uniq.each do |sharee_id|
      next if sharee_id.nil? #If document is shared with DocytBot, sharee_id is nil
      if self.document.standard_document
        notify_to_connected_user!(current_user, sharee_id, "#{current_user.first_name} has added new pages for the document: #{self.document.standard_document.name}")
      else
        notify_to_connected_user!(current_user, sharee_id, "#{current_user.first_name} has added a new document: #{self.document.original_file_name} that needs your review") unless current_user.advisor? #Advisor uploaded documents that are un-categorized are not shown to user's until they are categorized by Advisor
      end
    end
  end

  def notify_updated_page_to_connected_users!(current_user)
    self.document.all_sharees_ids.uniq.each do |sharee_id|
      next if sharee_id.nil? #If document is shared with DocytBot, sharee_id is nil
      notify_to_connected_user!(current_user, sharee_id, "#{current_user.first_name} has updated some pages of the document: #{self.document.standard_document.name}")
    end
  end

  def notify_to_connected_user!(current_user, recipient_id, message)
    return if current_user.id == recipient_id
    notification = Notification.new
    notification.sender = User.find_by_id(current_user.id)
    notification.recipient = User.find_by_id(recipient_id)
    notification.message = message
    
    if self.document.standard_document
      notification.notifiable = self.document
      notification.notification_type = Notification.notification_types[:document_update]
    else
      notification.notification_type = Notification.notification_types[:auto_categorization]
    end
    if notification.save
      notification.deliver([:push_notification])
    end
  end

end
