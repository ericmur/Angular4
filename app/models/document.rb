require 's3'
require 'aasm'
require 'slack_helper'
require 'transactional_query'

class Document < ActiveRecord::Base
  THIRD_PARTY_SOURCE = "AnotherApp"
  DOCYT_BOT_ACCESS_DURATION = 24*60 #minutes
  include AASM
  include StorageCalculateable
  include TransactionalQuery
  include DocumentFieldNotification
  include DocumentOwnerAndSharingNotification
  include DocumentPermissionMixins
  include StandardBaseDocumentPermissionMixins

  attr_accessor :share_with_system

  has_many :symmetric_keys, :dependent => :destroy
  has_many :pages, :dependent => :destroy
  has_many :document_fields, :dependent => :destroy #These are just the custom document fields for this document created by user on top of the standard_document_fields that are available to every document
  has_many :document_field_values, :dependent => :destroy
  belongs_to :uploader, :foreign_key => 'consumer_id', :class_name => 'User'
  belongs_to :standard_document
  belongs_to :suggested_standard_document, :class_name => 'StandardDocument', :foreign_key => 'suggested_standard_document_id'
  has_many :document_owners, :dependent => :destroy
  has_many :favorites, :dependent => :destroy
  belongs_to :cloud_service_authorization
  belongs_to :cloud_service_folder, :class_name => 'CloudServicePath', :foreign_key => 'cloud_service_path_id'
  belongs_to :email
  alias_attribute :cloud_service_folder_id, :cloud_service_path_id
  has_many :document_access_requests, dependent: :destroy
  has_many :faxes, dependent: :nullify
  has_one  :chat_document, dependent: :destroy
  has_many :workflow_document_uploads, dependent: :destroy
  has_many :document_preparers, dependent: :destroy
  has_many :business_documents, dependent: :destroy
  has_many :businesses, through: :business_documents
  has_many :document_permissions, dependent: :destroy
  has_many :docyt_bot_session_documents, :dependent => :destroy

  validates :cloud_service_full_path, uniqueness: { scope: [:consumer_id, :cloud_service_authorization_id] }, :allow_nil => true

  before_validation :build_s3_key, :on => :create
  before_create :set_favorite_if_needed_on_create
  after_create :create_notification_for_owners
  after_create :create_permissions_for_uploader
  after_save :update_uploader_permissions_if_needed
  after_destroy :delete_s3_object

  validates_associated :symmetric_keys

  validates :consumer_id, :presence => true, :if => Proc.new { |m| m.document_owners.first and !m.from_cloud_scan? }

  validate do |document|
   if !document.from_cloud_scan? && !document.is_source_chat? && !document.is_source_fax?
     if document.consumer_id && !document.business_document?
       if document.document_owners.first.nil?
         document.errors[:base] << "No document owner provided when uploading the document"
       end
     end
   end

    doc_owners = document.document_owners.select { |d| d.owner_type == GroupUser.to_s }
    if doc_owners.map(&:user_id).include?(document.uploader_id)
      document.errors[:base] << "Cannot upload document into a group user account instead upload into user account when it is the same user"
    end

    #Need to validate standard_document since it could be set by Categorization app
    if self.suggested_standard_document_id and self.suggested_standard_document.nil?
      document.errors[:base] << "Invalid Suggested Standard Document"
    end
  end

  scope :categorized, lambda { where.not(:standard_document_id => nil) }

  scope :belonging_to_group_users, lambda { |guids|
    if guids[2] #quicker way to check if more than 1
      joins(:document_owners).where("owner_id in (?) and owner_type in (?)", guids, GroupUser)
    elsif guids.first
      joins(:document_owners).where("owner_id in (?) and owner_type in (?)", guids, GroupUser)
    else
      none
    end
  }

  scope :owned_by, -> (user_id) {
    where(
      "EXISTS (#{DocumentOwner.only_connected_owners
                  .where(DocumentOwner.arel_table[:document_id].eq(Document.arel_table[:id]))
                  .where(owner_id: [user_id].flatten).select("1").to_sql})"
    )
  }

  scope :not_assigned, -> (advisor_id) {
    joins(:document_owners)
    .group('documents.id')
    .having('count(document_owners.id) = 1')
    .owned_by(advisor_id)
  }

  scope :not_owned_by, -> (user_id) {
    where(
      "NOT EXISTS (#{DocumentOwner.only_connected_owners
                  .where(DocumentOwner.arel_table[:document_id].eq(Document.arel_table[:id]))
                  .where(owner_id: [user_id].flatten).select("1").to_sql})"
    )
  }

  scope :accessible_by_me, -> (user) {
    joins(:symmetric_keys).where(symmetric_keys: { created_for_user_id: user.id })
  }

  scope :for_consumer_and_group_users_of, -> (consumer) {
    owner_list = consumer.group_users_as_group_owner.map {|g| [g.owner_id, g.owner_type] } << [consumer.id, consumer.class.to_s]
    conds = owner_list.map do |e|
      owner_type = e[1] == "GroupUser" ? "\'#{e[1]}\'" : "\'User\'"
      "(document_owners.owner_id = #{e[0]} AND document_owners.owner_type = #{owner_type})"
    end.join(" OR ")
    joins(:document_owners).where(conds)
  }

  aasm column: :state do
    state :pending, :initial => true
    state :uploading
    state :uploaded
    state :converting
    state :converted

    event :start_upload, :after => :upload_to_s3_if_cloud_scan do
      transitions from: [:pending, :uploading, :converting], to: :uploading
    end

    event :complete_upload, :after => :update_storage_size_from_s3 do
      transitions from: [:pending, :uploading], to: :uploaded, guard: :s3_object_exists? #UseCase for Pending => Uploaded transition: When user on phone kills the app right after it has created pages (pending state) but not yet made the next api call to mark the state as "uploading"
    end

    event :start_convertation, :after => :convert_document_to_img_or_flatten do
      transitions from: :uploaded, to: :converting
    end

    # Also added the transition from :uploaded to :converted
    # Because on ProcessEmailFromS3Job, we do upload the file inside same process.
    # And doesn't need the callback from :staart_converation event (:convert_document_to_img_or_flatten),
    # while doing convertation process on ProcessEmailFromS3Job.
    # So we will go directly to :complete_convertation when object is on :uploaded state
    event :complete_convertation do
      transitions from: [:converting, :uploaded], to: :converted
    end
  end

  def compile_primary_name(u, &speech_block)
    primary_name = self.standard_document.primary_name[0]
    args = self.standard_document.primary_name.slice(0..-1)
    if args
      args = args.map { |arg|
        compile_speech_text_field_value(arg, u, &speech_block)
      }
      primary_name % args
    else
      primary_name
    end
  end

  def uploader_email
    uploader.email if uploader
  end

  def is_source_chat?
    Chat::SOURCE.values.include?(self.source)
  end

  def is_source_fax?
    self.source == Fax::SOURCE
  end

  def needs_sharing_with_docytbot?
    (self.docyt_bot_access_expires_at && self.docyt_bot_access_expires_at > Time.now) || Resque.enqueued?(ConvertDocumentPagesToPdfJob, self.id) || Resque.enqueued?(GenerateFirstPageThumbnailJob, self.id)
  end

  def expire_time
    field_value = self.document_field_values.select{ |d| d.base_standard_document_field.notify }.first
    if field_value && field_value.value.present?
      Date.strptime(field_value.value, "%m/%d/%Y")
    end
  end

  def is_owned_by?(u)
    u.document_ownerships.where(:document_id => self.id).first
  end

  def saveable_from_external_service_by?(user)
    document_owners.empty? && accessible_by_me?(user) && [CloudService::DROPBOX, CloudService::GOOGLE_DRIVE, CloudService::ONE_DRIVE, 'WebChat', 'MobileChat'].include?(source)
  end

  def sharees_for_documents_except_system
    doc_owner_uids = self.document_owners.only_connected_owners.map(&:owner_id)
    self.symmetric_keys.where.not(:created_for_user_id => doc_owner_uids).where.not(:created_for_user_id => nil).map(&:created_for_user)
  end
  
  def sharees_for_documents
    doc_owner_uids = self.document_owners.only_connected_owners.map(&:owner_id)
    self.symmetric_keys.where.not(:created_for_user_id => doc_owner_uids).map(&:created_for_user)
  end

  def owners_for_documents
    doc_owner_uids = document_owners.only_connected_owners.map(&:owner_id)
    doc_owner_uids << consumer_id
    symmetric_keys.where(:created_for_user_id => doc_owner_uids.uniq).map(&:created_for_user)
  end

  def all_sharees_ids
    self.symmetric_keys.pluck(:created_for_user_id)
  end

  def all_sharees_ids_except_system
    self.symmetric_keys.where.not(:created_for_user_id => nil).pluck(:created_for_user_id)
  end

  def consumer_ids_for_owners
    consumer_ids = User.where(id: all_sharees_ids_except_system).select('id').map(&:id)
    consumer_ids << self.consumer_id # always include uploader/creator
    consumer_ids.uniq.reject(&:blank?)
  end

  def document_business_partner?(user_id)
    businesses.joins(:business_partners).where(business_partners: { user_id: user_id }).exists?
  end

  def business_document?
    self.business_documents.first
  end

  #Used to archive any document that was suggested by DocytBot and rejected by user
  def archive!
    DocumentArchive.create!(:consumer_id => self.consumer_id, :suggested_standard_document_id => self.suggested_standard_document_id, :rejected_at => Time.now, :suggested_at => self.suggested_at, :source => self.source, :file_content_type => self.file_content_type, :cloud_service_full_path => self.cloud_service_full_path, :original_file_name => self.original_file_name)
  end

  def uploader_id
    self.consumer_id
  end

  def ensure_valid_standard_document
    errors.add('StandardDocument') if self.standard_document_id and self.standard_document
  end

  def upload_to_s3_if_cloud_scan
    SaveDocumentToS3Job.perform_later(self.id) if from_cloud_scan?
  end

  def from_cloud_scan?
    self.cloud_service_full_path != nil
  end

  def s3_object_exists?
    return false if (self.final_file_key.blank? and self.original_file_key.blank?)

    bucket = Aws::S3::Bucket.new(ENV['DEFAULT_BUCKET'])
    obj = nil
    if self.final_file_key
      obj = bucket.objects({
                             max_keys: 1,
                             prefix: self.final_file_key
                           }).first
    else
      obj = bucket.objects({
                             max_keys: 1,
                             prefix: self.original_file_key
                           }).first
    end

    return obj.present?
  end

  def has_connected_owners?
    self.document_owners.only_connected_owners.select("1").first.present?
  end

  def has_user_access?
    self.symmetric_keys.select("1").first.present?
  end

  def accessible_by_me?(current_user)
    self.symmetric_keys.for_user_access(current_user.id).select("1").present?
  end

  def should_destroyed?(current_user)
    !has_connected_owners? && !accessible_by_me?(current_user) && owned_by_my_non_connected_user?(current_user)
  end

  def owned_by_my_non_connected_user?(current_user)
    non_connected_ids = current_user.groups_as_owner.first.group_users.where(user_id: nil).select("id").map(&:id)
    return self.document_owners.exists?(owner_type: 'GroupUser', owner_id: non_connected_ids)
  end

  def all_pages_uploaded?
    if self.pages.where.not(:state => "uploaded").select(1).present?
      return false
    else
      return true
    end
  end

  def share_with_system_for_duration(opts)
    self.share_with(opts.merge(:with_user_id => nil))

    #Get short term access for categorization related analysis
    self.update(docyt_bot_access_expires_at: (Time.now + DOCYT_BOT_ACCESS_DURATION.minutes))
  end

  def share_with(opts)
    # We will encrypt the symmetric key with the other user's public key to
    # share this document with him
    by_user_id = opts[:by_user_id]
    with_user_id = opts[:with_user_id]
    if with_user_id.class == Array
      with_user_ids = with_user_id
      return self.transactional_execute do
        with_user_ids.each do |with_user_id|
          symm_key = self.symmetric_keys.for_user_access(with_user_id).first
          if symm_key.nil?
            create_symmetric_key_for_user(:by_user_id => by_user_id, :with_user_id => with_user_id)
          end
        end
      end
    else
      symm_key = self.symmetric_keys.for_user_access(with_user_id).first
      if symm_key.nil?
        return create_symmetric_key_for_user(:by_user_id => by_user_id, :with_user_id => with_user_id)
      end
      return true
    end
  end

  def revoke_sharing(opts)
    with_user_id = opts[:with_user_id]
    symmetric_keys = self.symmetric_keys.for_user_access(with_user_id)
    raise "Multiple document keys detected for same user #{with_user_id} for document: #{self.id}" if symmetric_keys.count > 1
    symmetric_key = symmetric_keys.first
    if symmetric_key.nil?
      return
    end

    #Archive the symmetric key before destroying it so we know the history of sharing of a document
    SymmetricKeyArchive.create!({
                                  :created_for_user_id => symmetric_key.created_for_user_id,
                                  :created_by_user_id => symmetric_key.created_by_user_id,
                                  :document_id => symmetric_key.document_id,
                                  :symmetric_key_created_at => symmetric_key.created_at})
    symmetric_key.destroy
    if with_user_id.nil? #system/docytBot
      self.update(docyt_bot_access_expires_at: nil)
    end
    Favorite.where(document_id: self.id, consumer_id: with_user_id).destroy_all
  end

  def create_advisor_group_user!(current_user, advisor)
    self.document_owners.each do |document_owner|
      if document_owner.connected?
        group_user = current_user.group_users_as_group_owner.where(user_id: document_owner.owner_id).first
      else
        group_user = current_user.group_users_as_group_owner.where(id: document_owner.owner_id).first
      end
      if group_user.present?
        group_user_advisor = advisor.group_user_advisors.where(group_user_id: group_user.id).first
        group_user_advisor = advisor.group_user_advisors.create!(group_user_id: group_user.id) if group_user_advisor.blank?
      end
    end
  end

  def is_owner_or_uploader?(current_user)
    self.document_owners.where(owner: current_user).exists? || self.uploader_id == current_user.id
  end

  def add_business(business)
    unless business_documents.where(business_id: business.id).exists?
      business_documents.build(business: business)
    end
  end

  def generate_permissions_for_business_partners(user, business)
    business.business_partners.each do |business_partner|
      DocumentPermission.create_permissions_if_needed(self, business_partner.user, DocumentPermission::BUSINESS_PARTNER)
    end
  end

  def generate_folder_settings
    return if self.standard_document_id.blank?
    folder_settings_generated = 0
    owners = self.document_owners.to_a

    users = User.where(id: self.all_sharees_ids_except_system).select('id')

    users.each do |user|
      owners.each do |doc_owner|
        if doc_owner.connected?
          group_user = user.group_users_as_group_owner.where(user_id: doc_owner.owner_id).first
        else
          group_user = user.group_users_as_group_owner.where(id: doc_owner.owner_id).first
        end

        folder_owner = nil
        displayed_folders_ids = []

        if group_user.present?
          folder_owner = group_user
          if group_user.structure_type == GroupUser::FOLDER || group_user.structure_type.nil?
            displayed_folders_ids = standard_document.standard_folder_standard_documents.map(&:standard_folder_id)
          elsif group_user.structure_type == GroupUser::FLAT
            displayed_folders_ids = [standard_document_id]
          end
        elsif doc_owner.connected? && doc_owner.owner_id == user.id
          folder_owner = doc_owner.owner
          displayed_folders_ids = standard_document.standard_folder_standard_documents.map(&:standard_folder_id)
        else
          Rails.logger.info "No candidate for folder_owner found. Document: #{self.id} DocumentOwner: #{doc_owner.id}"
          next
        end

        displayed_folders_ids.each do |folder_id|
          user_folder_setting = user.user_folder_settings.where(standard_base_document_id: folder_id, folder_owner: folder_owner).first
          if user_folder_setting
            user_folder_setting.displayed = true
          else
            user_folder_setting = user.user_folder_settings.build(standard_base_document_id: folder_id, folder_owner: folder_owner, displayed: true)
          end
          if user_folder_setting.save!
            folder_settings_generated += 1
          end
        end
      end
    end

    folder_settings_generated
  end

  def generate_folder_settings_for_business
    return if standard_document.blank?
    return unless business_document?
    displayed_folders_ids = standard_document.standard_folder_standard_documents.map(&:standard_folder_id)
    users = User.where(id: all_sharees_ids_except_system).select('id')

    businesses.each do |business|
      users.each do |user|
        displayed_folders_ids.each do |folder_id|
          user_folder_setting = user.user_folder_settings.where(standard_base_document_id: folder_id, folder_owner: business).first
          if user_folder_setting
            user_folder_setting.displayed = true
          else
            user_folder_setting = user.user_folder_settings.build(standard_base_document_id: folder_id, folder_owner: business, displayed: true)
          end
          user_folder_setting.save
        end
      end
    end
  end

  def generate_standard_base_document_permissions
    return unless (standard_document && standard_document.consumer_id.present?)

    is_business_document = self.standard_document.business_document?
    owners_for_documents.each do |user|
      generate_standard_base_document_permissions_for_owner(standard_document, user, is_business_document, document_business_partner?(user))
    end

    sharees_for_documents_except_system.each do |user|
      if document_business_partner?(user)
        create_permissions_entries(standard_document, Permission::VALUES, user)
      else
        create_permissions_entries(standard_document, [Permission::VIEW], user)
      end
    end
  end

  def generate_standard_base_document_owners_for_business
    businesses.each do |business|
      return unless (standard_document && standard_document.consumer_id.present?)

      unless standard_document.owners.where(owner: business).exists?
        standard_document.owners.create(owner: business)
      end

      standard_document.standard_folder_standard_documents.each do |sfsd|
        standard_folder = sfsd.standard_folder
        next unless standard_folder.consumer_id.present?
        unless standard_folder.owners.where(owner: business).exists?
          standard_folder.owners.create(owner: business)
        end
      end
    end
  end

  def is_existing_owner?(user_id)
     self.document_owners.where(owner_type: 'User', owner_id: user_id).exists?
  end

  def remove_symmetric_key_for_users(removed_connected_owners_ids)
    self.symmetric_keys.for_user_access(removed_connected_owners_ids).each do |symm_key|
      SymmetricKeyArchive.create!(:created_for_user_id => symm_key.created_for_user_id, :created_by_user_id => symm_key.created_by_user_id, :document_id => symm_key.document_id, :symmetric_key_created_at => symm_key.created_at)
      symm_key.destroy
    end
  end

  def remove_favorites_for_users(removed_connected_owners_ids)
    removed_connected_owners_ids.each do |removed_owner_id|
      Favorite.where(consumer_id: removed_owner_id, document_id: self.id).destroy_all
    end
  end

  def update_owners_symmetric_key(current_user)
    document_owners.only_connected_owners.each do |document_owner|
      next if self.document_access_requests.created_by(document_owner.owner_id).exists?
      if self.symmetric_keys.for_user_access(document_owner.owner_id).select(:id).first.nil?
        self.share_with(:by_user_id => current_user.id, :with_user_id => document_owner.owner_id)
      end
    end
  end

  def document_extension
    @document_extension ||= DocumentExtensionService.new(self.file_content_type, self.original_file_key)
  end

  # converts uploaded document by advisor to images for iPhone users
  def convert_document_to_img_or_flatten
    if document_extension.microsoft_file?
      ConvertMicrosoftFileToPdfJob.perform_later(self.id)
    elsif document_extension.image_file?
      ConvertDocumentImgToPdfJob.perform_later(self.id)
    elsif document_extension.pdf_file?
      if is_source_chat?
        #If document came in as drag and drop in web app chat, then just flatten
        #it. Don't convert it to pages yet - that will be done when this doc
        #is saved.
        FlattenPdfJob.perform_later(self.id)
      else
        ConvertDocumentPdfToImgJob.perform_later(self.id)
      end
    else
      SlackHelper.ping({channel: "#errors", username: "DocumentExtensionService", message: "Invalid file extension when trying to convert Document: #{self.id}"})
    end
  end

  def recalculate_storage_size_for_owners(deleted_owners_ids)
    deleted_owners_ids.each do |owner_id|
      UserStorageSizeCounterJob.perform_later(owner_id)
    end
  end

  # Update the storage size with actual size on S3
  def update_storage_size_from_s3
    FetchS3ObjectLengthJob.perform_later(self.class.to_s, self.id)
  end

  # This method will be called from FetchS3ObjectLengthJob
  def perform_update_storage_size_from_s3
    total_size = 0
    if self.final_file_key
      total_size += fetch_object_size(self.final_file_key)
    else
      total_size += fetch_object_size(self.original_file_key)
    end
    self.update_column(:storage_size, total_size)
    recalculate_storage_size
  end

  def update_with_owners(current_user, document_params, document_owners_params)
    self.transaction do
      begin
        removed_connected_owners_ids = []
        if document_owners_params.present?
          removed_connected_owners_ids = self.document_owners.only_connected_owners.where.not(:owner_id => document_owners_params.select { |hsh| hsh["owner_type"] == "User" }.map { |hsh| hsh["owner_id"] }).select(:owner_id).map(&:owner_id)
        end
        new_document_owners = recreate_document_owners(current_user, document_owners_params)

        #Remove symmetric keys access for all owners that were removed except current_user. Current User will not expect his access to be removed
        self.symmetric_keys.for_user_access(removed_connected_owners_ids - [current_user.id]).each do |symm_key|
          SymmetricKeyArchive.create!(:created_for_user_id => symm_key.created_for_user_id, :created_by_user_id => symm_key.created_by_user_id, :document_id => symm_key.document_id, :symmetric_key_created_at => symm_key.created_at)
          symm_key.destroy
        end

        self.update!(document_params)
        self.update_owners_symmetric_key(current_user)

        generate_standard_base_document_permissions
        generate_folder_settings
      rescue => e
        self.errors.add(:base, e.message)
        raise ActiveRecord::Rollback
      end
    end

    return self.errors.empty?
  end

  def self.check_expiring_documents
    DocumentFieldValue.where.not(value: nil).find_each(batch_size: 100) do |doc_field|
      doc_field.process_notify_durations(true)
    end
  end

  def build_symmetric_key_for_user(opts)
    by_user_id = opts[:by_user_id]
    with_user_id = opts[:with_user_id]
    symmetric_keys = self.symmetric_keys.for_user_access(by_user_id)
    raise "Multiple document keys detected for same user #{by_user.id} for document: #{self.id}" if symmetric_keys.count > 1
    symmetric_key = symmetric_keys.first
    decrypted_key = symmetric_key.decrypt_key
    decrypted_iv = symmetric_key.decrypt_iv
    symmetric_key = self.symmetric_keys.build(:created_by_user_id => by_user_id, :created_for_user_id => with_user_id, :key => decrypted_key, :iv => decrypted_iv)
  end

  def update_initial_pages_completion
    return if initial_pages_completed?
    if self.pages.uploaded.count == self.pages.count
      self.update_column(:initial_pages_completed, true)
    end
  end

  def process_completion_from_sns_notification(object_key)
    return false if self.uploaded?
    self.original_file_key = object_key
    if self.complete_upload && self.save
      fax = Fax.for_document(self.id).first
      fax.enqueue_send_fax if fax.present?
      DocumentCacheService.update_cache([:document], self.consumer_ids_for_owners)
    end
  end

  def standard_folder_name
    if self.standard_document_id
      Document.joins(standard_document: { standard_folder_standard_documents: :standard_folder })
        .where(id: self.id)
        .select("standard_folders_standard_folder_standard_documents.name AS standard_folder_name").first[:standard_folder_name]
    end
  end

  def standard_document_name
    self.standard_document.name if self.standard_document_id
  end

  def update_uploader_permissions_if_needed
    return if consumer_id_was.blank?
    if consumer_id_changed?
      rebuild_document_permissions_for(User.find(consumer_id_was))
      create_permissions_for_uploader
    end
  end

  def transfer_document_permissions(previous_owner, new_owner)
    destroy_document_permissions_for(new_owner)
    create_document_permissions_for(new_owner, DocumentPermission::OWNER)

    destroy_document_permissions_for(previous_owner)
    rebuild_document_permissions_for(previous_owner)
  end

  def create_permissions_for_uploader
    create_document_permissions_for(uploader, DocumentPermission::UPLOADER)
  end

  private

  def recreate_document_owners(current_user, document_owners_params)
    self.document_owners.destroy_all
    new_document_owners = []

    if document_owners_params.present?
      document_owners_params.each do |owner_hash|
        if owner_hash["owner_type"] == "GroupUser"
          g_user = GroupUser.find(owner_hash["owner_id"])
          new_document_owners << self.document_owners.create!(owner: g_user.user_id ? g_user.user : g_user)
        elsif owner_hash["owner_type"] == "User"
          new_document_owners << self.document_owners.create!(owner: User.find(owner_hash["owner_id"]))
        elsif owner_hash["owner_type"] == "Client"
          client = Client.find(owner_hash["owner_id"])
          new_document_owners << self.document_owners.create!(owner: client.user_id ? client.user : client)
        elsif owner_hash["owner_type"] == "Advisor"
          advisor = User.with_standard_category.find(owner_hash["owner_id"])
          new_document_owners << self.document_owners.create!(owner: advisor)
        else
          raise "Invalid type: #{owner_hash["owner_type"]}"
        end
      end
    else #If there is no owner specified, just make current_user the owner
      unless self.document_owners.where(owner: User.find(current_user.id)).present?
        new_document_owners << self.document_owners.create!(owner: User.find(current_user.id))
      end
    end

    new_document_owners
  end

  def create_symmetric_key_for_user(opts)
    symmetric_key = build_symmetric_key_for_user(opts)
    begin
      symmetric_key.save #Could create PG::UniqueViolation::Error
    rescue PG::UniqueViolation, ActiveRecord::RecordNotUnique => e
      return false
    end
  end

  def create_symmetric_key_for_user!(opts)
    symmetric_key = build_symmetric_key_for_user(opts)

    symmetric_key.save!
  end

  def delete_s3_object
    DeleteS3ObjectJob.perform_later(self.original_file_key) unless self.original_file_key.blank?
  end

  def build_s3_key
    #Give uploader access to the document whether or not he is the owner of the document
    s3_encryptor = S3::DataEncryption.new
    symmetric_key = self.symmetric_keys.build(:created_by_user_id => self.uploader_id, :key => s3_encryptor.encryption_key, :iv => s3_encryptor.encryption_iv, :created_for_user_id => self.uploader_id)

    self.document_owners.each do |doc_owner|
      if doc_owner.owner_type == GroupUser.to_s
        # If this document is being uploaded for a group user, then we have to
        # give the other "group user" access to this document too.
        if doc_owner.owner.user
          other_user_symmetric_key = self.symmetric_keys.build(:created_by_user_id => self.uploader_id, :key => s3_encryptor.encryption_key, :iv => s3_encryptor.encryption_iv, :created_for_user_id => doc_owner.owner.user_id)
        end

        #If Advisor is uploading a document for a contact of a client then document should be shared with the client too.
        if self.uploader.advisor?
          group_owner_id = doc_owner.owner.group.owner_id
          group_owner_symmetric_key = self.symmetric_keys.build(:created_by_user_id => self.uploader_id, :key => s3_encryptor.encryption_key, :iv => s3_encryptor.encryption_iv, :created_for_user_id => group_owner_id)
        end
      elsif doc_owner.consumer?
        symmetric_key = self.symmetric_keys.build(:created_by_user_id => self.uploader_id, :key => s3_encryptor.encryption_key, :iv => s3_encryptor.encryption_iv, :created_for_user_id => doc_owner.owner_id)
      elsif doc_owner.owner_type == Client.to_s
        # If this document is being uploaded for a client, then we have to
        # give the "client" access to this document too.
        if doc_owner.owner.consumer
          if doc_owner.owner.consumer
            other_user_symmetric_key = self.symmetric_keys.build(:created_by_user_id => self.uploader_id, :key => s3_encryptor.encryption_key, :iv => s3_encryptor.encryption_iv, :created_for_user_id => doc_owner.owner.consumer_id)
          end
        end
      else
        raise "Invalid type: #{doc_owner.owner_type}"
      end
    end

    #If source is cloud scan or email then keys need to be shared with DocytBot. For this share_with_system attribute is set to true when creating document
    if self.share_with_system
      self.symmetric_keys.build(:created_by_user_id => nil, :key => s3_encryptor.encryption_key, :iv => s3_encryptor.encryption_iv, :created_for_user_id => nil)
    end
  end

  def set_favorite_if_needed_on_create
    self.favorites.build(:consumer_id => self.consumer_id) if DefaultFavorite.where(:standard_document_id => self.standard_document_id).first
  end

  def compile_speech_text_field_value(arg, u, &speech_block)
    val = self.document_field_values.where(:local_standard_document_field_id => arg["field_id"].to_i).first
    if val
      val.user_id = u.id  #To get the private key to decrypt incase of secure field
      val = val.field_value
      if arg["processor"]
        val = StandardDocumentField.send(arg["processor"].to_sym, val)
      end

      if arg["speech_type"]
        speech_block.call(val, arg['speech_type'])
      end
      val
    else
      ""
    end
  end
end
