require 'serializer_scope'
require 'system_encryption'
require 'slack_helper'

class UserDocumentCache < ActiveRecord::Base
  belongs_to :user

  validates :user_id, presence: true
  validates :version, presence: true, uniqueness: { scope: [:user_id] }
  validates :encrypted_password_hash, presence: true

  after_destroy do
    UserDocumentJson.where(user_id: self.user_id).destroy_all
  end

  def self.update_cache(user_ids)
    user_ids = user_ids.flatten.uniq
    UserDocumentCache.update_document_caches_version(user_ids)

    #####The call below is a bit low level but since we process creation of JSON in a separate background server, we should commit transactions before enqueueing
    ActiveRecord::Base.connection.commit_db_transaction unless Rails.env.test? || Rails.env.development?
    user_ids.each do |user_id|
      Resque.enqueue UserDocumentCacheUpdatesJob, user_id
    end
  end

  # wrapper to get the lastest version number
  def self.latest(user_id)
    UserDocumentCache.where(user_id: user_id).order(version: :desc).first
  end

  # find or create user_document_cache and construct for the first time if version equal 0
  def self.document_cache_for(user)
    user_document_cache = self.latest(user.id)
    if user_document_cache.nil?
      self.generate_document_cache_for(user)
    else
      user_document_cache.update_mobile_app_version(Rails.mobile_app_version)
      user_document_cache
    end
  end

  def self.generate_document_cache_for(user)
    password_hash = Rails.user_password_hash
    mobile_app_version = Rails.mobile_app_version
    encrypted_password_hash = SystemEncryption.new(:encryption_type => 'pgp').encrypt(password_hash, { encode_base64: true })
    user_document_cache = UserDocumentCache.where(user_id: user.id, version: 0).first
    user_document_cache = UserDocumentCache.create!(user: user, version: 0, encrypted_password_hash: encrypted_password_hash, mobile_app_version: mobile_app_version) if user_document_cache.nil?
    user_document_cache
  end

  def self.update_existing_caches(user_ids)
    user_ids.each do |user_id|
      self.update_document_cache_for(user_id)
    end
  end

  # this should happens before start queue job
  def self.update_document_caches_version(user_ids)
    user_ids.each do |user_id|
      user_document_cache = UserDocumentCache.latest(user_id)
      unless user_document_cache.nil?
        user_document_cache.bump_version
      end
    end
  end

  # for update, enqueue only existing UserDocumentCache as password_hash is now saved in database
  # and at this point there's less possible way to directly get all users password_hash from controller
  def self.update_document_cache_for(user_id)
    user_document_cache = UserDocumentCache.latest(user_id)
    unless user_document_cache.nil?
      user_document_cache.enqueue_construct_job
    end
  end

  def bump_version
    self.with_lock do
      self.reload
      self.version += 1
      self.save!
    end
  end

  def update_mobile_app_version(new_mobile_app_version)
    return if new_mobile_app_version.blank?
    if self.mobile_app_version.nil? || self.mobile_app_version != new_mobile_app_version
      self.update_column(:mobile_app_version, new_mobile_app_version)
      self.bump_version
      UserDocumentCache.update_document_cache_for(self.user_id)
    end
  end

  # active record resource
  def resource
    folders = StandardFolder.only_system.only_category
    folders = folders.union(StandardFolder.only_category.viewable_by_user(self.user_id))
    folders.order(rank: :asc)
  end

  def enqueue_construct_job
    Resque.enqueue UserDocumentJsonConstructionJob, self.user_id
  end

  def update_password_hash!(password_hash)
    encrypted_password_hash = SystemEncryption.new(:encryption_type => 'pgp').encrypt(password_hash, { encode_base64: true })
    self.encrypted_password_hash = encrypted_password_hash
    self.save!
  end

  # this method will be invoke in UserDocumentJsonConstructionJob
  def generate_document_json
    if Rails.env.development?
      puts "Processing queue. Old Document cache for User: #{self.user_id}" # useful for debugging
    end

    if UserDocumentJson.where(user_id: self.user.id, version: self.version).exists?
      message = "Attempting to generate already existing UserDocumentJson version: #{self.version}. User: #{self.user_id}"
      SlackHelper.ping({ channel: "#warnings", username: "DocumentCache (v1)", message: message })
      UserDocumentJson.where(:user_id => self.user_id).destroy_all
    end

    user_password_hash = SystemEncryption.new(:encryption_type => 'pgp').decrypt(self.encrypted_password_hash, base64_encoded: true)
    Rails.set_user_password_hash(user_password_hash)
    Rails.set_mobile_app_version(self.mobile_app_version)
    Rails.set_app_type(User::MOBILE_APP)
    scope = SerializerScope.new
    scope.current_user = self.user
    scope.params = {}

    json_data = ActiveModel::ArraySerializer.new(resource, root: 'documents', each_serializer: StandardFolderSerializer, scope: scope ).to_json
    encrypted_json_data = SystemEncryption.new.encrypt(json_data, encode_base64: true)
    user_docs = UserDocumentJson.create!(user_id: self.user.id, version: self.version, document_json: encrypted_json_data)
    self.cleanup_document_json
  end

  def current_document_json
    UserDocumentJson.where(user_id: self.user_id).order(version: :desc).first
  end

  # return json blob if version is greater than 0
  # 0 is the default version value
  # after first construction version number will be 1
  def document_json
    dj = current_document_json

    if dj.nil?
      Rails.logger.info "Enqueue Cache creation"
      enqueue_construct_job
      Rails.logger.info "Load DocumentJSON from Serializer"
      return resource
    end

    if self.version > dj.version
      Rails.logger.info "Enqueue Cache creation"
      enqueue_construct_job
      Rails.logger.info "Load DocumentJSON from Serializer"
      return resource
    elsif self.version == dj.version
      Rails.logger.info "Load DocumentJSON from Cache"
      decrypted_json_data = SystemEncryption.new.decrypt(dj.document_json, base64_encoded: true)
      return decrypted_json_data
    else
      # invalid case, bump version and enqueue new job
      Rails.logger.info "Invalid UserDocumentCache version. Bump version and re-queque"
      notifier = Slack::Notifier.new SLACK_WEBHOOK_URL
      notifier.ping "Invalid UserDocumentData(#{self.id}). UserDocumentJSON version that is greater than data version.", channel: '#errors', username: 'UserDocumentDataBot'
      self.version = dj.version
      self.save
      enqueue_construct_job
      Rails.logger.info "Load DocumentJSON from Serializer"
      return resource
    end
  end

  def cleanup_document_json
    UserDocumentJson.where(:user_id => self.user_id).where({'version' => {'$lt' => self.version }}).destroy_all
    nil
  end
end
