require 'transactional_query'

class Client < ActiveRecord::Base
  include TransactionalQuery
  include FolderSettingGenerator

  belongs_to :consumer, :class_name => 'User'
  belongs_to :advisor, :class_name => 'User'
  belongs_to :business

  has_one :avatar, dependent: :destroy, as: :avatarable

  validates :name, :presence => true, :if => Proc.new { |obj| obj.consumer_id.nil? }
  validates :email, :uniqueness => { scope: :advisor_id, message: "can only be associated once with the same advisor" }, :allow_blank => true
  validates :email, :uniqueness => { scope: :consumer_id, message: "can only be associated once with the same consumer"}, :allow_blank => true
  validates :phone, :uniqueness => { scope: :advisor_id, message: "can only be associated once with the same advisor" }, :allow_blank => true
  validates :phone, :uniqueness => { scope: :consumer_id, message: "can only be associated once with the same consumer" }, :allow_blank => true

  validates_plausible_phone :phone, :normalized_country_code => 'US'
  phony_normalize :phone, :as => :phone_normalized, :default_country_code => 'US'

  has_many :document_ownerships, as: :owner, class_name: 'DocumentOwner', dependent: :destroy
  has_many :invitations, dependent: :destroy, class_name: Invitationable::AdvisorToConsumerInvitation.to_s, foreign_key: 'client_id'
  has_many :standard_base_document_ownerships, :as => :owner, :class_name => 'StandardBaseDocumentOwner', :dependent => :destroy
  has_many :chats_users_relations, :dependent => :destroy, :as => :chatable
  has_many :user_folder_settings, dependent: :destroy, as: :folder_owner

  validates :consumer_id, :uniqueness => { scope: :advisor_id, message: "can only be associated once with same advisor" }, :allow_blank => true
  validates :advisor_id, :presence => true
  validates :business_id, presence: { message: 'cannot be blank. If you are unable to select business, please update your app version.' }

  before_save :clear_client_data, :if => Proc.new { |obj| obj.consumer_id }
  after_save :create_chat_if_missing!, :if => Proc.new { |obj| obj.consumer_id and obj.advisor_id } #Create chat only when client is connected
  after_save :set_documents_ownerships, :if => Proc.new { |obj| obj.consumer_id && obj.advisor_id }

  def connected?
    self.consumer.present?
  end

  def user_id
    self.consumer_id
  end

  def user
    self.consumer
  end

  def first_name
    self.owner_name.split(' ').first
  end

  def owner_name
    self.connected? ? self.consumer.parsed_fullname : self.name
  end

  def owner_avatar
    self.connected? ? self.consumer.avatar : self.avatar
  end

  def owner_email
    self.connected? ? self.consumer.email : self.email
  end

  def owner_phone
    self.connected? ? self.consumer.phone : self.phone
  end

  def owner_birthday
    self.consumer.birthday if self.consumer
  end

  def owner_phone_normalized
    self.connected? ? self.consumer.phone_normalized : self.phone_normalized
  end

  def documents_ids_shared_with_advisor
    docs_ids = nil
    if self.consumer_id
      consumer_docs_ids = self.consumer.document_ownerships.select(:document_id)
      docs_ids = SymmetricKey.for_user_access(self.advisor_id).where(:document_id => consumer_docs_ids).pluck(:document_id)
    else
      docs_ids = self.document_ownerships.pluck(:document_id)
    end
    docs_ids
  end

  def unlink!
    unlinked = true
    ActiveRecord::Base.transaction do
      begin
        user = self.consumer
        self.name = user.name
        self.consumer_id = nil
        if self.save!
          SymmetricKey.for_document_owned_by(user.id).for_document_not_owned_by(advisor.id).for_user_access(advisor.id).destroy_all
          user.favorites.where(document_id: Document.owned_by(advisor).select(:id).map(&:id)).destroy_all
          Invitationable::Invitation.where(client_id: self.id).destroy_all
          self.destroy
          DocumentCacheService.update_cache([:standard_folder, :standard_document, :document, :folder_setting], [user.id, advisor.id])
        end
      rescue => e
        self.errors.add(:base, e.message)
        unlinked = false
        raise ActiveRecord::Rollback
      end
    end
    return unlinked
  end

  def last_message_in_client_chat
    return unless consumer && advisor

    chat = Api::Web::V1::ChatsManager.new(advisor, [consumer]).find_or_create_with_users
    chat.messages.last.created_at if chat.messages.any?
  end

  def employees_count(advisor)
    return 0 unless self.user

    get_business_contacts(self.user, advisor, GroupUser::EMPLOYEE)
  end

  def contractors_count(advisor)
    return 0 unless self.user

    get_business_contacts(self.user, advisor, GroupUser::CONTRACTOR)
  end

  def contacts_count(advisor)
    return 0 unless self.user

    base_contacts_query(user, advisor).where.not(label: [GroupUser::EMPLOYEE, GroupUser::CONTRACTOR]).count
  end

  private

  def create_chat_if_missing!
    chat = Api::Web::V1::ChatsManager.new(self.advisor, [self.consumer]).find_or_create_with_users
  end

  def set_documents_ownerships
    doc_ownerships = self.document_ownerships.to_a
    doc_ownerships.each do |doc_ownership|
      doc = doc_ownership.document
      user_key = doc.build_symmetric_key_for_user(:by_user_id => self.advisor_id, :with_user_id => self.consumer_id)
      user_key.save!
      doc_ownership.owner_id = self.consumer_id
      doc_ownership.owner_type = User.to_s
      doc_ownership.save!
      doc.transfer_document_permissions(advisor, user) # transfer document permission from current user to newly assigned user
      doc.generate_standard_base_document_permissions
    end

    stdoc_ownerships = self.standard_base_document_ownerships.to_a
    stdoc_ownerships.each do |stdoc_ownership|
      stdoc_ownership.owner_id = self.consumer_id
      stdoc_ownership.owner_type = User.to_s
      stdoc_ownership.save!
    end
  end

  #We clear client data from this model in this method as when this method is
  #invoked above via "before_save", we save it in consumer model anyway - no need
  #to duplicate

  def clear_client_data
    self.phone = self.phone_normalized = self.email = self.name = nil
  end

  def invitations_count
    Invitationable::AdvisorToConsumerInvitation.where(created_by_user_id: self.advisor_id, client_id: self.id).size
  end

  def sended_invitation_days_ago
    invitation = Invitationable::AdvisorToConsumerInvitation.where(created_by_user_id: self.advisor_id, client_id: self.id).where(accepted_at: nil).first
    (Time.now.to_date - invitation.created_at.to_date).to_i if invitation
  end

  def get_business_contacts(user, advisor, condition)
    return 0 unless user.consumer_account_type_id == ConsumerAccountType::BUSINESS

    base_contacts_query(user, advisor).where(label: condition).count
  end

  def base_contacts_query(user, advisor)
    user.group_users_as_group_owner.joins(group_user_advisors: :advisor).where("users.id = ?", advisor.id)
  end
end
