require 'encryption'
require 'token_utils'

class User < ActiveRecord::Base
  PHONE_COUNTRY_CODE = 'US'
  PHONE_CONFIRM_MESSAGE = "Your code is: %s. Please confirm your phone number by entering this code in your Docyt App when requested"
  CHANGE_PHONE_CONFIRM_MESSAGE = "Your code is: %s. Please confirm your phone number by entering this code."
  FORGET_PIN_MESSAGE = "Your code is: %s. You have requested to reset your PIN for your Docyt Account. Please confirm by entering this code in your Docyt App when requested."

  SERVICE_PROVIDER_SOURCE = "ServiceProvider"
  MOBILE_APP = "MobileApp"
  WEB_APP = "WebApp"
  DOCYT_BOT_APP = "DocytBotApp"

  MINIMUM_UPLOADED_DOCUMENTS_TO_REVIEW_APP = 3

  include TokenUtils

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable

  EMAIL_REGEX = /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i

  attr_accessor :pin
  attr_accessor :pin_confirmation
  attr_accessor :app_type #Tells us the app type that user is using: WebApp or iPhoenApp. This is needed to decide if password is needed or pin is needed during login/signup. This will be set in the relevant controller/action depending on if it was web app's controller/action or iphone app's controller/action
  alias_attribute :pin_private_key, :private_key #Name is deceptive, in "private_key" field private_key is encrypted with PIN

  before_validation :create_pgp_keys, :on => :create

  validates_plausible_phone :phone, :normalized_country_code => PHONE_COUNTRY_CODE  #Required for authenticating multiple devices
  validates :private_key, presence: true, :if => Proc.new { |user| user.from_mobile_app? }
  validates :password_private_key, presence: true, :if => Proc.new { |user| user.from_web_app? }
  validates :public_key, presence: true
  validate :phone_presence
  validates :total_pages_count, :total_storage_size, presence: true
  validates :upload_email, :uniqueness => true, :allow_blank => true
  validates :email, :uniqueness => true, :allow_blank => true #Until user signs up for web app, email is not needed
  validates :email, email: true, :allow_blank => true
  validates :phone, uniqueness: true, if: Proc.new { |user| !user.phone.nil? }

  validates :password, :presence => true,
                       :confirmation => true,
                       :length => { :within => 8..40 },
                       :on => :create, :if => Proc.new { |user| user.from_web_app? }

  validates :password_confirmation, :presence => true, :on => :create, :if => Proc.new { |user| user.from_web_app? }
  validates :pin, confirmation: true, :on => :create, :if => Proc.new { |user| user.from_mobile_app? }
  validates :pin_confirmation, presence: true, :on => :create, :if => Proc.new { |user| user.from_mobile_app? }
  validates_length_of :pin, is: 6, message: "PIN should be 6 digits long", on: :create, :if => Proc.new { |user| user.from_mobile_app? }
  validates :pin, format: { with: /\d+/, message: "only allows digits" }, on: :create, :if => Proc.new { |user| user.from_mobile_app? }

  validates :standard_category_id, :uniqueness => true, :if => Proc.new { |advisor| advisor.standard_category_id == StandardCategory::DOCYT_SUPPORT_ID } #Only one support advisor model is allowed

  phony_normalize :phone, :as => :phone_normalized, :default_country_code => PHONE_COUNTRY_CODE

  validate :real_phone_number

  has_one :user_migration, :dependent => :destroy
  has_one :avatar, dependent: :destroy, as: :avatarable
  has_one :iphone_contact_list, dependent: :destroy
  has_one :user_statistic, dependent: :destroy
  has_one :user_credit, dependent: :destroy
  has_one :review, dependent: :destroy

  has_many :symmetric_keys_from_me, :class_name => "SymmetricKey", :foreign_key => 'created_by_user_id', :dependent => :nullify
  has_many :symmetric_keys_for_me, :class_name => "SymmetricKey", :foreign_key => 'created_for_user_id', :dependent => :destroy
  has_many :group_users, :dependent => :destroy # TODO: Instead of destroy, do unlink
  has_many :user_accesses, :foreign_key => 'accessor_id', :dependent => :destroy
  has_many :user_accessors, :foreign_key => 'user_id', :class_name => "UserAccess"
  has_many :groups, :through => :group_users
  has_many :groups_as_owner, :class_name => "Group", :foreign_key => 'owner_id', :dependent => :destroy
  has_many :group_users_as_group_owner, :through => :groups_as_owner, :source => :group_users
  has_many :cloud_service_authorizations, :dependent => :destroy
  has_many :chats_users_relations, :as => :chatable, :dependent => :destroy
  has_many :chats, :through => :chats_users_relations
  has_many :message_users, -> { where(receiver_type: "User") }, :dependent => :destroy, :class_name => 'Messagable::MessageUser', :foreign_key => 'receiver_id'
  has_many :locations, dependent: :destroy, as: :locationable
  has_many :uploaded_documents, :dependent => :nullify, :class_name => 'Document', :foreign_key => 'consumer_id' #These are the documents uploaded by this consumer/advisor
  has_many :pages, :through => :uploaded_documents
  has_many :standard_base_documents_by_me, :foreign_key => 'consumer_id', :class_name => 'StandardBaseDocument' #someday we will change this foreign key name to created_by_user_id. DONOT add dependent => nullify as otherwise deleting a user will make their custom standard documents as standard documents
  has_many :document_fields_by_me, :foreign_key => 'created_by_user_id', :class_name => 'DocumentField' #DONOT add dependent => nullify as otherwise deleting a user will make their custom document fields as standard document fields
  has_many :notifications, dependent: :destroy, foreign_key: 'recipient_id'
  has_many :user_document_caches, dependent: :destroy, class_name: 'UserDocumentCache'
  has_many :uploaded_emails, :class_name => 'Email'
  has_many :user_folder_settings, dependent: :destroy
  has_many :document_access_requests_as_requestor, :class_name => 'DocumentAccessRequest', :foreign_key => 'created_by_user_id', :dependent => :destroy
  has_many :document_access_requests_as_requestee, :class_name => 'DocumentAccessRequest', :foreign_key => 'uploader_id', :dependent => :destroy

  has_many :suggested_documents_for_upload, -> { where("suggested_standard_document_id is not null and standard_document_id is null") }, :class_name => 'Document', :foreign_key => "consumer_id" #These are the documents suggested by DocytBot from cloud Services (like Dropbox, Drive) of the user
  has_many :uploaded_documents_via_email, -> { where("standard_document_id is null and source = 'ForwardedEmail'") }, :class_name => 'Document', :foreign_key => "consumer_id"
  has_many :uploaded_and_categorized_documents, -> { where.not(standard_document_id: nil) }, class_name: 'Document'

  has_many :document_ownerships, :dependent => :destroy, :as => :owner, :class_name => 'DocumentOwner'
  has_many :standard_base_document_ownerships, :dependent => :destroy, :as => :owner, :class_name => 'StandardBaseDocumentOwner'
  has_many :standard_document_field_ownerships, :dependent => :destroy, :as => :owner, :class_name => 'StandardDocumentFieldOwner'

  belongs_to :standard_category
  has_many :clients_as_advisor, :dependent => :destroy, :class_name => 'Client', :foreign_key => 'advisor_id'
  has_many :client_seats, :dependent => :nullify, :class_name => 'Client', :foreign_key => 'consumer_id' #This user is Client to other advisors
  has_many :advisors, :through => :client_seats

  has_many :favorites, :dependent => :destroy, :foreign_key => 'consumer_id'

  has_many :cloud_service_paths, :dependent => :destroy, :foreign_key => 'consumer_id'

  has_many :devices, :dependent => :destroy
  has_many :push_devices, :dependent => :destroy
  has_many :confirmed_devices, -> { where("devices.confirmed_at is not null") }, :dependent => :destroy, :class_name => 'Device'

  #This is used to represent the account type user chose in signup screens in Mobile app where we ask if user has small business paperwork or not. If he says he does his consumer_account_type corresponds to "Business", otherwise it is "Family". This affects the default folders that will be visible to him on first login (he can always customize them after that).
  belongs_to :consumer_account_type
  belongs_to :business_information
  belongs_to :referrer, foreign_key: 'referrer_id', class_name: 'User'

  #User contacts that are shared with Service Provider are the only contacts of the client that Service Provider can see. SP can then upload documents for these contacts.
  has_many :group_user_advisors, dependent: :destroy, :foreign_key => 'advisor_id'
  has_many :group_users, through: :group_user_advisors

  has_many :invitations, :dependent => :destroy, class_name: Invitationable::AdvisorToConsumerInvitation.to_s, foreign_key: 'created_by_user_id'

  has_many :faxes, dependent: :destroy, foreign_key: 'sender_id'

  has_many :workflows, dependent: :destroy, foreign_key: 'admin_id'
  has_many :workflow_document_uploads, dependent: :destroy

  has_many :participants, dependent: :nullify
  has_many :document_preparers, foreign_key: 'preparer_id', dependent: :destroy
  has_many :business_partnerships, class_name: 'BusinessPartner', dependent: :destroy
  has_many :businesses, through: :business_partnerships
  has_many :credit_cards, :dependent => :destroy
  has_many :subscriptions, :dependent => :destroy
  has_many :payment_transactions, :dependent => :destroy
  has_many :user_credit_promotions, dependent: :destroy
  has_one :referral_code, dependent: :destroy

  before_save  :encrypt_pin, :if => Proc.new { |user| user.from_mobile_app? }
  after_save   :clear_pin, :if => Proc.new { |user| user.from_mobile_app? }
  after_create :send_phone_token, :if => Proc.new { |user| user.from_mobile_app? }
  after_create :create_invitation_notification
  after_create :create_user_migration_entry
  after_create :send_welcome_email, :if => :email_present?
  after_create :generate_email_confirmation_token, :if => :email_present?
  after_create :connect_docyt_support_advisor
  after_commit :generate_upload_email_in_background, on: :create
  after_destroy :destroy_user_document_json
  after_create :set_last_time_notifications_read_at
  after_create do
    user_credit = self.build_user_credit
    user_credit.save
  end
  after_create :process_signup_referral
  after_create :create_referral_code

  after_create :setup_standard_base_document_permissions

  scope :with_standard_category, -> { where.not(standard_category_id: nil) }

  def real_phone_number
    return if Rails.env.development? || Rails.env.test?
    return if self.phone_confirmed_at.present? || self.phone_confirmation_sent_at.present?
    if self.phone and !(TwilioClient.valid_phone_number?(self.phone))
      errors.add(:phone, 'is invalid')
    end
  end

  def has_advisor?(uid)
    Client.where(advisor_id: uid, consumer_id: self.id).exists?
  end

  def phone_presence
    if self.phone_normalized && User.where(:phone_normalized => self.phone_normalized).where.not(:id => self.id).first
      errors.add(:base, "User already exists with that Phone Number")
    end
  end

  def recalculate_storage_size(val = nil)
    if val.nil?
      us = [self, self.unconnected_group_users_as_group_owner, self.clients_as_advisor].flatten
      pages_storage = Page.where(:document_id => DocumentOwner.by_owners(us).map(&:document_id)).non_document_storage.sum(:storage_size)
      docs_storage = Document.where(:id => DocumentOwner.by_owners(us).map(&:document_id)).document_storage.sum(:storage_size)
      val = pages_storage + docs_storage
    end
    self.update_column(:total_storage_size, val.to_i)
    val
  end

  def recalculate_page_count(val = nil)
    if val.nil?
      us = [self, self.unconnected_group_users_as_group_owner, self.clients_as_advisor].flatten
      val = Page.where(:document_id => DocumentOwner.by_owners(us).map(&:document_id)).count
    end
    self.update_column(:total_pages_count, val.to_i)
  end

  def destroy_user_document_json
    UserDocumentJson.where(user_id: self.id).destroy_all
  end

  def generate_upload_email_in_background
    GenerateUploadEmailJob.perform_later(self.id) if self.errors.empty?
  end

  def create_user_migration_entry
    m = self.build_user_migration
    m.save!
  end

  def create_pgp_keys
    pgp = Encryption::Pgp.new(:password => self.password_hash)
    if self.from_web_app?
      self.password_private_key = pgp.private_key
    elsif self.from_mobile_app?
      self.private_key = pgp.private_key
    else
      raise "Invalid type: #{self.app_type}"
    end
    self.public_key = pgp.public_key
  end

  def email_present?
    self.email
  end

  def advisor?
    self.standard_category_id
  end

  def docyt_support?
    self.standard_category_id == StandardCategory::DOCYT_SUPPORT_ID
  end

  def from_web_app?
    self.app_type == WEB_APP
  end

  def from_mobile_app?
    self.app_type == MOBILE_APP
  end

  def has_pin?
    self.encrypted_pin.present?
  end

  def self.verify_email_token(token)
    @user = User.where(email_confirmation_token: token).first
    if @user
      if @user.email_confirmed_at.present?
        false
      elsif Time.zone.now - @user.email_confirmation_sent_at > 5.days
        false
      else
        unless @user.unverified_email.blank?
          @user.set_verified_email
        else
          @user.confirm_email
        end
      end
    else
      false
    end
  end

  def resend_phone_confirmation_code(opts = {})
    if opts[:type] == 'web'
      field = :web_phone_confirmation_token
    else
      field = :phone_confirmation_token
    end

    send_token(:confirmation_token_field => field,
               :phone => self.phone_normalized,
               :message => PHONE_CONFIRM_MESSAGE
              )
  end

  def generate_email_confirmation_token
    if email_confirmation_token.blank? || (email_confirmation_sent_at && Time.zone.now - email_confirmation_sent_at > 1.day)
      generate_token_for_field('email_confirmation_token')
      self.email_confirmation_sent_at = Time.zone.now
    end
    self.email_confirmed_at = nil
    self.save
    send_email_confirmation
  end

  def has_fullname?
    self.first_name.present? && self.last_name.present?
  end

  def email_confirmed?
    self.email_confirmed_at.present?
  end

  def confirmed_phone?
    self.phone_confirmed_at.present?
  end

  def confirm_phone(opts = {})
    if opts[:type] == 'web'
      self.web_phone_confirmation_token = nil
      self.web_phone_confirmed_at = DateTime.now
    else
      self.phone_confirmation_token = nil
      self.phone_confirmed_at = DateTime.now
    end
    self.save
  end

  def set_verified_phone_number
    self.phone = self.unverified_phone
    self.unverified_phone = nil
    self.confirm_phone
  end

  def send_phone_token(opts = {})
    if opts[:type] == 'web'
      confirmation_token_field   = :web_phone_confirmation_token
      confirmation_sent_at_field = :web_phone_confirmation_sent_at
    else
      confirmation_token_field   = :phone_confirmation_token
      confirmation_sent_at_field = :phone_confirmation_sent_at
    end

    generate_and_send_token(:confirmation_token_field => confirmation_token_field,
                            :confirmation_sent_at_field => confirmation_sent_at_field,
                            :phone => self.phone_normalized,
                            :message => PHONE_CONFIRM_MESSAGE
                          )
  end

  def send_phone_token_for_verified_new_phone_number
    generate_and_send_token(
                            :confirmation_token_field => :phone_confirmation_token,
                            :confirmation_sent_at_field => :phone_confirmation_sent_at,
                            :phone => PhonyRails.normalize_number(self.unverified_phone, :country_code => User::PHONE_COUNTRY_CODE),
                            :message => CHANGE_PHONE_CONFIRM_MESSAGE
                           )
  end

  def update_auth_encrypted_private_key(password)
    pwh = self.password_hash(password)
    password_pgp = Encryption::Pgp.new(:private_key => self.password_private_key, :password => pwh)
    auth_token_pgp = Encryption::Pgp.new(:private_key => password_pgp.unencrypted_private_key, :password => self.authentication_token)
    self.update(auth_token_private_key: auth_token_pgp.private_key)
  end

  def update_oauth_encrypted_private_key_using_pin(pin, token)
    ph = self.password_hash(pin)
    ph_pgp = Encryption::Pgp.new(:private_key => self.private_key, :password => ph)
    oauth_token_pgp = Encryption::Pgp.new(:private_key => ph_pgp.unencrypted_private_key, :password => token)
    self.update(oauth_token_private_key: oauth_token_pgp.private_key)
  end

  #MD5 hash of password. It is not saved in DB, because otherwise anyone could read it from the DB and decrypt user's private key - against our policy that nobody should be able to read user data other than user himself.
  def password_hash(p = nil)
    pass = p ? p : self.passphrase
    raise 'Passphrase is nil' if pass.blank?
    Encryption::MD5Digest.new.digest_base64(pass)
  end

  def passphrase
    if self.from_mobile_app?
      self.pin
    elsif self.from_web_app?
      self.password
    else
      raise "Invalid type: #{self.app_type}"
    end
  end

  def run_migrations
    self.run_field_values_migration
    self.user_migration.migrate_to_create_pdfs_for_documents
    self.user_migration.migrate_to_create_first_page_thumbnail
  end

  def parse_fullname(name)
    fullname = name.split(" ")
    if fullname.count == 1
      self.first_name = fullname[0]
      self.middle_name = ""
      self.last_name = ""
    elsif fullname.count == 2
      self.first_name = fullname[0]
      self.middle_name = ""
      self.last_name = fullname[1]
    elsif fullname.count == 3
      self.first_name = fullname[0]
      self.middle_name = fullname[1]
      self.last_name = fullname[2]
    elsif fullname.count > 3
      self.first_name = fullname[0]
      self.middle_name = fullname[1..fullname.count-2].join(" ")
      self.last_name = fullname[fullname.count-1]
    end
  end

  def parsed_fullname
    name.present? ? name : email
  end

  def name
    [self.first_name, self.middle_name, self.last_name].reject(&:blank?).join(' ')
  end

  #The following owner_<method> are common helper methods available across user, group_user and client models. This way same method calls can be invoked on connected/unconnected users.
  def owner_name
    self.parsed_fullname
  end

  def owner_email
    self.email
  end

  def owner_avatar
    self.avatar
  end

  def cleanup_locations
    recent_ids = self.locations.order(created_at: :desc).limit(10).select("id").map(&:id)
    self.locations.where.not(id: recent_ids).destroy_all unless recent_ids.blank?
  end

  def cleanup_old_notifications
    recent_ids = self.notifications.order(created_at: :desc).limit(100).select("id").map(&:id)
    self.notifications.where.not(id: recent_ids).destroy_all unless recent_ids.blank?
  end

  def confirm_email
    self.email_confirmation_token = nil
    self.email_confirmed_at = Time.zone.now
    self.save
  end

  def valid_pin?(pin)
    self.encrypted_pin == BCrypt::Engine.hash_secret(pin, self.salt)
  end

  def update_pin(pin, new_private_key)
    ActiveRecord::Base.transaction do
      begin
        self.pin = pin
        pwh = self.password_hash
        pgp = Encryption::Pgp.new(:private_key => new_private_key, :password => pwh)
        self.private_key = pgp.private_key
        self.public_key = pgp.public_key
        if self.save!
          user_document_cache = UserDocumentCache.where(user_id: self.id).first
          user_document_cache.update_password_hash!(pwh) if user_document_cache
        end
      rescue => e
        self.errors[:base] << e.message
        raise ActiveRecord::Rollback
      end
    end
    return self.errors.empty?
  end

  def set_password_private_key_using_new_password(pass)
    auth_token_pgp = Encryption::Pgp.new(:private_key => self.auth_token_private_key, :password => self.authentication_token)
    password_pgp = Encryption::Pgp.new(:private_key => auth_token_pgp.unencrypted_private_key, :password => self.password_hash(pass))
    self.password_private_key = password_pgp.private_key
  end

  def valid_forgot_pin_token?(forgot_pin_token)
    self.forgot_pin_token == forgot_pin_token
  end

  def clean_up_pins
    self.pin = self.pin_confirmation = nil
  end

  def send_forget_pin_code
    generate_and_send_token(:confirmation_token_field => :forgot_pin_token, :confirmation_sent_at_field => :forgot_pin_token_sent_at, :phone => self.phone_normalized, :message => FORGET_PIN_MESSAGE)
  end

  def confirm_forgot_pin_token
    self.forgot_pin_token = nil
    self.forgot_pin_confirmed_at = Time.now
    self.save
  end

  def add_device!(device_name, device_uuid)
    device = Device.where(:device_uuid => device_uuid).first

    if device
      device.user_id = self.id
      device.name = device_name
      device.confirmed_at = Time.now
      device.confirmation_sent_at = nil
      device.save!
    else
      device = self.devices.build(:name => device_name, :device_uuid => device_uuid, :confirmed_at => Time.now)
      device.save!
    end
  end

  def has_device_confirmed?(device_uuid)
    self.confirmed_devices.where(device_uuid: device_uuid).exists?
  end

  def eligible_to_review?
    uploaded_documents.count >= MINIMUM_UPLOADED_DOCUMENTS_TO_REVIEW_APP
  end

  def recreate_device(device_name, device_uuid)
    self.devices.where(device_uuid: device_uuid).destroy_all
    device = self.devices.build(:name => device_name, :device_uuid => device_uuid)
    device.save
  end

  def update_app_version
    unless self.mobile_app_version == Rails.mobile_app_version
      self.update_column(:mobile_app_version, Rails.mobile_app_version)
    end
  end

  def uploaded_documents_via_email_for_clients
    Document.not_assigned(self.id).where( standard_document_id: nil, source: 'ForwardedEmail' )
  end

  def uploaded_document_via_email_for_client(document_id)
    Document.not_assigned(self.id).find_by( standard_document_id: nil, source: 'ForwardedEmail', id: document_id )
  end

  def setup_standard_base_document_permissions
    Permission.bulk_insert(:standard_base_document_id, :user_id, :folder_structure_owner_id, :folder_structure_owner_type, :value, :created_at, :updated_at) do |worker|
      StandardBaseDocument.only_system.select('id').find_each do |standard_base_document_id|
        Permission::VALUES.each do |value|
          worker.add standard_base_document_id: standard_base_document_id, user_id: id, folder_structure_owner_id: id, folder_structure_owner_type: 'User', value: value, created_at: Time.zone.now, updated_at: Time.zone.now
        end
      end
    end
    puts "Warning: This generator intended to be used for first time only. Running this twice will create duplicate entries."
  end

  def set_verified_email
    self.email = self.unverified_email
    self.unverified_email = nil
    self.confirm_email
  end

  def create_invitation_notification
    invitations = Invitationable::Invitation.pending.where(phone_normalized: self.phone_normalized)
    invitations.each do |invitation|
      invitation.generate_notification_for_created_invitation(self)
    end
  end

  def connect_docyt_support_advisor
    advisor = StandardCategory.where(:id => StandardCategory::DOCYT_SUPPORT_ID).first.advisors.first
    return if advisor.id == self.id #Don't add DocytSupport as a client to itself
    unless advisor.clients_as_advisor.where(:consumer_id => self.id).first
      advisor.clients_as_advisor.create!(:consumer_id => self.id, business: advisor.businesses.first)
    end
  end

  def unconnected_group_users_as_group_owner
    self.group_users_as_group_owner.where("group_users.user_id is null")
  end

  def find_or_create_cloud_service_path(params)
    unless cloud_service_path = self.cloud_service_paths.where(params).first
      cloud_service_path = self.cloud_service_paths.create!(params)
    end

    return cloud_service_path
  end

  def has_available_storage?(new_file_size, new_pages_count)
    not_exceeded_pages_limit?(new_pages_count.to_i) && not_exceeded_storage_limit?(new_file_size.to_i)
  end

  def has_not_exceeded_storage?
    not_exceeded_pages_limit? and not_exceeded_storage_limit?
  end

  def run_field_values_migration
    return if self.fields_encryption_migration_done?
    document_ids = ::Api::Mobile::V2::DocumentsQuery.new(self, { }).get_documents.map(&:id)
    DocumentFieldValue.where(document_id: document_ids).find_each do |field_value|
      field_value.user_id = self.id
      field_value.migrate_value!
    end
    self.update_column(:fields_encryption_migration_done, true)
    DocumentCacheService.update_cache([:document], [self.id])
  end

  def suggested_documents_count
    self.uploaded_documents_via_email.union(self.suggested_documents_for_upload).count
  end

  def unread_notifications_count
    if self.last_time_notifications_read_at.present?
      created_at_column = Notification.arel_table[:created_at]
      created_at_from_timestamp_query = created_at_column.gt(self.last_time_notifications_read_at)
      self.notifications.unread.where(created_at_from_timestamp_query).count
    else
      self.notifications.unread.count
    end
  end

  def unread_messages_count
    n = 0
    self.chats_users_relations.each do |c|
      messages_users = Messagable::MessageUser.joins(:message).where(receiver: self, messages: { chat_id: c.chat_id }, read_at: nil)
      if c.last_time_messages_read_at.present?
        created_at_column = Messagable::MessageUser.arel_table[:created_at]
        created_at_from_timestamp_query = created_at_column.gt(c.last_time_messages_read_at)
        messages_users = messages_users.where(created_at_from_timestamp_query)
      end
      n += messages_users.distinct.count
    end
    n
  end

  def app_badge_counter
    unread_notifications_count + suggested_documents_count + unread_messages_count
  end

  def update_password_encrypted_private_key(pin, password)
    pwh = self.password_hash(pin)
    pin_pgp = Encryption::Pgp.new(private_key: self.private_key, password: pwh)
    password_pgp = Encryption::Pgp.new(private_key: pin_pgp.unencrypted_private_key, password: self.password_hash(password))
    self.update(password_private_key: password_pgp.private_key)
  end

  def web_app_is_set_up?
    password_private_key.present?
  end

  def current_business_name
    if self.consumer_account_type and self.consumer_account_type.business?
      return Business.find_by(id: current_workspace_id).name if current_workspace_name == Business.name.to_s and current_workspace_id != nil
    else
      return nil
    end
  end

  def business_names
    return [] unless (self.consumer_account_type and self.consumer_account_type.business?)
    businesses.map { |business| { id: business.id, name: business.name } } if businesses.any?
  end

  def process_signup_referral
    ProcessSignupReferralJob.perform_later(self.id)
  end

  def process_signup_referral_without_delay
    return unless referrer.present?
    ActiveRecord::Base.transaction do
      begin
        promotion_type = UserCreditPromotion::SIGNUP_PROMOTION
        credit_value = UserCreditPromotion::SIGNUP_CREDITS_BONUS
        unless referrer.user_credit_promotions.given_by(self).for_promotion_type(promotion_type).exists?
          subs_promo = referrer.user_credit_promotions.build(given_by: self, credit_value: credit_value, promotion_type: promotion_type)
          subs_promo.save!
          user_credit = referrer.user_credit
          user_credit.purchase_pages_credit!(subs_promo, subs_promo.credit_value, promotion_type, self.created_at)
        end
      rescue => e
        raise ActiveRecord::Rollback
      end
    end
  end

  private

  def create_referral_code
    attempts = 0
    begin
      referral_code = build_referral_code
      referral_code.code = SecureRandom.hex(3).downcase
      referral_code.save!
    rescue ActiveRecord::RecordNotUnique => e
      attempts = attempts.to_i + 1
      retry if attempts < 10
    end
  end

  def set_last_time_notifications_read_at
    User.where(id: self.id).update_all(last_time_notifications_read_at: Time.zone.now)
  end

  def encrypt_pin
    if pin.present?
      self.salt = BCrypt::Engine.generate_salt
      self.encrypted_pin = BCrypt::Engine.hash_secret(pin, self.salt)
    end
  end

  def clear_pin
    self.pin = nil
  end

  def send_welcome_email
    UserMailer.welcome_email(self).deliver_later(wait: 1.day)
  end

  def send_email_confirmation
    UserMailer.email_confirmation(self.id, self.email_confirmation_token).deliver_later
  end

  def not_exceeded_pages_limit?(new_pages_count = nil)
    (self.total_pages_count + (new_pages_count ? new_pages_count : 0)) <= self.limit_pages_count
  end

  def not_exceeded_storage_limit?(new_file_size = nil)
    (self.total_storage_size + (new_file_size ? new_file_size : 0)) <= self.limit_storage_size
  end

end
