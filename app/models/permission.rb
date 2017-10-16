class Permission < ActiveRecord::Base
  VIEW = 'VIEW'
  WRITE = 'WRITE'
  EDIT = 'EDIT'
  DELETE = 'DELETE'
  VALUES = [VIEW, WRITE, EDIT, DELETE]

  belongs_to :standard_base_document
  belongs_to :folder_structure_owner, polymorphic: true
  belongs_to :user

  validates :user_id, presence: true
  validates :folder_structure_owner_id, presence: true
  validates :folder_structure_owner_type, presence: true

  validates_associated :standard_base_document

  scope :for_standard_base_document_id, -> (std_doc_id) { where(standard_base_document_id: std_doc_id) }
  scope :for_user, -> (user) { where(user_id: user.id) }
  scope :for_owner, -> (owner) { where(folder_structure_owner: owner) }
  scope :with_value, -> (value) { where(value: value) }

  def description
    "#{user_id} #{folder_structure_owner_type} #{folder_structure_owner_id} #{value}"
  end

  def self.setup_system_business_documents_permissions_for(business, standard_base_documents_ids=[])
    standard_base_documents_ids = StandardBaseDocumentAccountType.only_system_for_consumer_account_type(ConsumerAccountType::BUSINESS).pluck(:standard_folder_id) if standard_base_documents_ids.blank?
    ActiveRecord::Base.transaction do
      begin
        business.business_partners.map(&:user).reject(&:nil?).each do |user|
          standard_base_documents_ids.each do |standard_base_document_id|
            Permission.create_permission!(standard_base_document_id, user, business)
          end
        end
      rescue => e
        Rails.logger.info e.message
      end
    end
  end

  def self.setup_system_documents_permissions_for_contact(user, contact, standard_base_documents_ids=[])
    standard_base_documents_ids = StandardBaseDocumentAccountType.only_system_for_consumer_account_type(ConsumerAccountType::INDIVIDUAL).pluck(:standard_folder_id) if standard_base_documents_ids.blank?
    ActiveRecord::Base.transaction do
      begin
        standard_base_documents_ids.each do |standard_base_document_id|
          Permission.create_permission!(standard_base_document_id, user, contact)
        end
      rescue => e
        Rails.logger.info e.message
      end
    end

  end

  def self.setup_system_documents_permissions_for(user, standard_base_documents_ids=[])
    standard_base_documents_ids = StandardBaseDocumentAccountType.only_system_for_consumer_account_type(ConsumerAccountType::INDIVIDUAL).pluck(:standard_folder_id) if standard_base_documents_ids.blank?
    ActiveRecord::Base.transaction do
      begin
        standard_base_documents_ids.each do |standard_base_document_id|
          user.group_users_as_group_owner.each do |group_user|
            if group_user.connected?
              Permission.create_permission!(standard_base_document_id, user, group_user)
              Permission.create_permission!(standard_base_document_id, user, group_user.user)
            else
              Permission.create_permission!(standard_base_document_id, user, group_user)
            end

          end
          user.clients_as_advisor.each do |client|
            owner = client.connected? ? client.consumer : client
            Permission.create_permission!(standard_base_document_id, user, owner)
          end
          Permission.create_permission!(standard_base_document_id, user, user)
        end
      rescue => e
        Rails.logger.info e.message
      end
    end
  end

  def self.create_permission!(standard_base_document_id, user, owner)
    Permission::VALUES.reject{ |v| v == DELETE }.each do |value|
      next if Permission.for_standard_base_document_id(standard_base_document_id)
        .for_user(user).for_owner(owner).with_value(value).exists?

      permission = Permission.new
      permission.standard_base_document_id = standard_base_document_id
      permission.folder_structure_owner = owner
      permission.user = user
      permission.value = value
      permission.save!
    end
  end
end
