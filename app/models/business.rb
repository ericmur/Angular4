class Business < ActiveRecord::Base
  ENTITY_TYPES = ["C-Corp", "S-Corp", "LLC", "Partnership", "Sole Proprietorship", "Foreign Entity", "Other"]

  belongs_to :standard_category
  has_one :avatar, dependent: :destroy, as: :avatarable
  has_many :business_partners, dependent: :destroy
  has_many :business_documents, dependent: :destroy
  has_many :user_folder_settings, dependent: :destroy, as: :folder_owner
  has_many :notifications, dependent: :destroy, as: :notifiable
  has_many :clients, dependent: :nullify
  has_many :group_users, dependent: :nullify
  has_many :emails, dependent: :nullify

  validates :name, presence: true
  validates :entity_type, presence: true
  validates :standard_category_id, presence: true
  validates :address_street , presence: true
  validates :address_city, presence: true
  validates :address_zip, presence: true
  validates :address_state, presence: true

  scope :for_user, -> (user) { joins(:business_partners).where(business_partners: { user_id: user.id }) }

  def business_partner?(user)
    business_partners.where(user_id: user.id).exists?
  end

  def generate_notifications_for_new_business!(current_user)
    business_partners.each do |business_partner|
      next if business_partner.user == current_user
      notification = Notification.new
      notification.recipient = business_partner.user
      notification.message = "#{current_user.first_name} added you as a business partner for #{name}"
      notification.notifiable = self
      notification.notification_type = Notification.notification_types[:business_updated]
      if notification.save!
        notification.deliver([:push_notification])
      end
    end
  end

  def migrate_partners_account_type_to_business!(current_user)
    business_partners.each do |business_partner|
      user = business_partner.user

      business_account_type = ConsumerAccountType.business_type.first.id
      next if user.consumer_account_type_id == business_account_type

      user.consumer_account_type_id = ConsumerAccountType.business_type.first.id
      if user.save!
        UserFolderSetting.setup_folder_setting_for_user(user)
      end
    end
  end

  def generate_folder_settings!
    account_type = ConsumerAccountType.business_type.first
    business_partners.each do |business_partner|
      account_type.standard_folders.each do |standard_folder|
        next if standard_folder.consumer_id.present?
        next if standard_folder.category == false
        user_folder_setting = business_partner.user.user_folder_settings.where(standard_base_document_id: standard_folder.id, folder_owner: self).first
        folder_show = standard_folder.default
        if user_folder_setting.nil?
          user_folder_setting = business_partner.user.user_folder_settings.build(standard_base_document_id: standard_folder.id, folder_owner: self, displayed: folder_show)
        else
          user_folder_setting.displayed = folder_show
        end
        user_folder_setting.save!
      end
      account_type.standard_documents.each do |standard_document|
        next if standard_document.consumer_id.present?
        user_folder_setting = business_partner.user.user_folder_settings.where(standard_base_document_id: standard_document.id, folder_owner: self).first
        folder_show = standard_document.default
        if user_folder_setting.nil?
          user_folder_setting = business_partner.user.user_folder_settings.build(standard_base_document_id: standard_document.id, folder_owner: self, displayed: folder_show)
        else
          user_folder_setting.displayed = folder_show
        end
        user_folder_setting.save!
      end
    end
  end

  def employees_count
    group_users_count(GroupUser::EMPLOYEE).size
  end

  def contractors_count
    group_users_count(GroupUser::CONTRACTOR).size
  end

  private

  def group_users_count(type)
    group_users.where(label: type)
  end
end
