require 'transactional_query'

class GroupUser < ActiveRecord::Base
  include TransactionalQuery
  include FolderSettingGenerator

  SPOUSE="Spouse"
  WIFE="Wife"
  HUSBAND="Husband"
  KID="Kid"
  SON="Son"
  DAUGHTER="Daughter"
  EMPLOYEE="Employee"
  CONTRACTOR="Contractor"
  COWORKER="Co-worker"
  DAD="Dad"
  MOM="Mom"
  BROTHER="Brother"
  SISTER="Sister"
  GRANDFATHER="Grandfather"
  GRANDMA="GrandMa"
  LABELS=[SPOUSE,WIFE,HUSBAND,KID,SON,DAUGHTER,EMPLOYEE,CONTRACTOR,COWORKER,DAD,MOM,BROTHER,SISTER,GRANDFATHER,GRANDMA]

  belongs_to :group
  belongs_to :business
  has_many   :group_user_advisors, dependent: :destroy
  has_many   :advisors, through: :group_user_advisors

  belongs_to :user  #These would mostly be consumers but there could be a case in the future where we would add advisors to the group too - hence we have user model here instead of consumer model
  has_one :avatar, dependent: :destroy, as: :avatarable
  has_many :standard_base_document_ownerships, :dependent => :destroy, :as => :owner, :class_name => 'StandardBaseDocumentOwner'
  has_many :document_ownerships, :dependent => :destroy, :class_name => 'DocumentOwner', :as => :owner
  has_one :invitation, dependent: :destroy, class_name: "Invitationable::Invitation"
  has_many :user_folder_settings, dependent: :destroy, as: :folder_owner

  validates :name, :presence => true, :if => Proc.new { |obj| obj.user_id.nil? }
  validates :group_id, :presence => true
  validates :user_id, :uniqueness => { scope: :group_id, message: "can only be associated once with the same group" }, :allow_blank => true
  validates :email, :uniqueness => { scope: :group_id, message: "has already been associated with another member in your Contacts" }, :allow_blank => true
  validates :phone, :uniqueness => { scope: :group_id, message: "has already been associated with another member in your Contacts" }, :allow_blank => true
  validates_plausible_phone :phone, :normalized_country_code => 'US'
  validates_associated :user, :if => Proc.new { |obj| obj.user_id }
  validates :business_id, presence: { message: 'cannot be blank. If you are unable to select business, please update your app version.' }, if: Proc.new { |obj| obj.require_business? }
  phony_normalize :phone, :as => :phone_normalized, :default_country_code => 'US'

  before_save :clear_user_data, :if => Proc.new { |obj| obj.user_id }
  after_save :create_chat_if_missing!, :if => Proc.new { |obj| obj.user_id } #Create chat only when client is connected

  def first_name
    self.name ? self.name.split(' ').first : nil
  end

  def last_name
    self.name ? self.name.split(' ').last : nil
  end

  def owner_name
    self.connected? ? self.user.parsed_fullname : self.name
  end

  def owner_email
    self.connected? ? self.user.email : self.email
  end

  def owner_phone
    self.connected? ? self.user.phone_normalized : self.phone_normalized
  end

  def owner_phone_normalized
    self.connected? ? self.user.phone_normalized : self.phone_normalized
  end

  def owner_avatar
    self.connected? ? self.user.avatar : self.avatar
  end

  def owner_id
    self.connected? ? self.user_id : self.id
  end

  def owner_type
    self.connected? ? 'User' : 'GroupUser'
  end

  def group_owner_id
    self.group.owner_id
  end

  def require_business?
    [EMPLOYEE, CONTRACTOR].map(&:downcase).include?(label.to_s.downcase)
  end

  def has_personal_relationship?(relationship_type)
    relationship_type = ::Api::DocytBot::V1::Matcher.new(nil).cleanup(relationship_type) #Remove trailing "'s"
    my_relationships = GroupUser.get_similar_personal_relationships_to(self.label)
    my_relationships.include?(relationship_type.downcase)
  end

  def self.get_similar_personal_relationships_to(relationship_type)
    if (rels = [SPOUSE.downcase, "wife", "husband", SPOUSE.downcase + "s", "wifes", "husbands"]).include?(relationship_type.downcase)
      return rels
    elsif (rels = [KID.downcase, "son", "daughter", KID.downcase + "s", "sons", "daughters"]).include?(relationship_type.downcase)
      return rels
    elsif (rels = ["brother", "sibling", "brothers", "siblings"]).include?(relationship_type.downcase)
      return rels
    elsif (rels = ["sister", "sibling", "brothers", "sisters"]).include?(relationship_type.downcase)
      return rels
    elsif (rels = ["dad", "father", "dads", "fathers"]).include?(relationship_type.downcase)
      return rels
    elsif (rels = ["mother", "mom", "mothers", "moms"]).include?(relationship_type.downcase)
      return rels
    elsif (rels = ["grandfather", "grandpa", "grandfathers", "grandpas"]).include?(relationship_type.downcase)
      return rels
    elsif (rels = ["grandmother", "grandma", "grandmothers", "grandpas"]).include?(relationship_type.downcase)
      return rels
    else
      return []
    end
  end

  def documents_ids_shared_with_user(u)
    docs_ids = nil
    if self.user_id
      docs_ids = self.user.document_ownerships.pluck(:document_id)
    else
      docs_ids = self.document_ownerships.pluck(:document_id)
    end
    SymmetricKey.for_user_access(u.id).where(:document_id => docs_ids).pluck(:document_id)
  end

  def number_of_documents
    if self.user.present?
      self.user.document_ownerships.joins(:document => :symmetric_keys).where('symmetric_keys.created_for_user_id' => self.group.owner_id).count
    else
      self.document_ownerships.count
    end
  end

  def number_of_expiring_documents
    if self.user.present?
      self.user.document_ownerships.joins(:document => [:symmetric_keys, :document_field_values]).where("symmetric_keys.created_for_user_id = ? AND document_field_values.notification_level > 0", self.group.owner_id).count
    else
      self.document_ownerships.joins(:document => :document_field_values).where("document_field_values.notification_level > 0").count
    end
  end

  def set_user(uid)
    self.transactional_save do
      set_user_without_transaction(uid)
    end
  end

  def set_user_without_transaction(uid)
    self.user_id = uid
    doc_ownerships = self.document_ownerships.to_a
    doc_ownerships.each do |doc_ownership|
      doc = doc_ownership.document
      DocumentAccessRequest.create!(document: doc, uploader_id: self.group.owner_id, created_by_user_id: uid)
      doc_ownership.owner_id = uid
      doc_ownership.owner_type = User.to_s
      doc_ownership.save!
      doc.transfer_document_permissions(group.owner, user) # transfer document permission from current user to newly assigned user
      doc.generate_standard_base_document_permissions
    end
    stdoc_ownerships = self.standard_base_document_ownerships.to_a
    stdoc_ownerships.each do |stdoc_ownership|
      stdoc_ownership.owner_id = uid
      stdoc_ownership.owner_type = User.to_s
      stdoc_ownership.save!
    end
    self.save!
  end

  def unlink!(&block)
    success = false
    message = nil

    ActiveRecord::Base.transaction do
      begin
        other_group_user = self.user.groups_as_owner.first.group_users.where(user_id: self.group.owner_id).first
        self.unlink
        other_group_user.unlink(true)

        self.destroy
        other_group_user.destroy

        success = true
      rescue => e
        message = e.message
        raise ActiveRecord::Rollback
      end
    end

    yield(success, message)
  end

  def unlink(notify=false)
    self.phone = user.phone unless group.group_users.exists?(phone_normalized: user.phone_normalized)
    self.email = user.email unless group.group_users.exists?(email: user.email)
    self.name = user.name
    uid = self.user_id
    self.user_id = nil
    self.unlinked_at = Time.zone.now

    if self.save!
      me = User.find(self.group.owner_id)
      their = User.find(uid)
      SymmetricKey.for_document_owned_by(their.id).for_document_not_owned_by(me.id).for_user_access(me.id).destroy_all
      their.favorites.where(document_id: Document.owned_by(me).select(:id).map(&:id)).destroy_all
      Invitationable::Invitation.where(group_user_id: self.id).destroy_all
      notify_unlinked if notify
      DocumentCacheService.update_cache([:standard_folder, :standard_document, :document, :folder_setting], [me.id])
    end
  end

  def notify_unlinked
    notification = Notification.new
    notification.recipient = User.find(self.group.owner_id)
    notification.message = "#{self.name} has been unlinked from your account."
    notification.notifiable = self
    notification.notification_type = Notification.notification_types[:unlinked_group_user]
    if notification.save!
      notification.deliver([:push_notification])
    end
  end

  def connected?
    self.user.present?
  end

  def copy_avatar_to_user
    if self.avatar.present? && self.avatar.uploaded? && self.user && self.user.avatar.blank?
      self.transactional_save do
        user_avatar = self.user.build_avatar
        user_avatar.save!
        user_avatar.reload
        user_avatar.s3_object_key = "avatar-#{user_avatar.id}.jpeg"
        s3 = AWS::S3.new
        s3.buckets[ENV['DEFAULT_BUCKET']].objects[user_avatar.s3_object_key].copy_from(self.avatar.s3_object_key)
        user_avatar.complete_upload!
      end
    end
  end

  def share_with_advisor(advisor)
    group_user_advisor = advisor.group_user_advisors.where(group_user: self).first
    if group_user_advisor
      return group_user_advisor
    else
      return advisor.group_user_advisors.create(group_user: self)
    end
  end

  def unshare_with_advisor(advisor)
    group_user_advisor = advisor.group_user_advisors.where(group_user: self).first
    group_user_advisor.destroy if group_user_advisor
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
    chat = Api::Web::V1::ChatsManager.new(self.group.owner, [self.user]).find_or_create_with_users
  end

  #We clear user data from this model in this method as when this method is
  #invoked above via "before_save", we save it in user model anyway - no need
  #to duplicate
  def clear_user_data
    self.phone = self.phone_normalized = self.email = self.name = nil
  end

  def get_business_contacts(user, advisor, condition)
    return 0 unless user.consumer_account_type_id == ConsumerAccountType::BUSINESS

    base_contacts_query(user, advisor).where(label: condition).count
  end

  def base_contacts_query(user, advisor)
    user.group_users_as_group_owner.joins(group_user_advisors: :advisor).where("users.id = ?", advisor.id)
  end

end
