class Api::Web::V1::AdvisorCreateForm < Api::Web::V1::BaseForm

  # advisor attributes
  attribute :id, Integer
  attribute :email, String
  attribute :password, String
  attribute :password_confirmation, String
  attribute :authentication_token, String, :default => Devise.friendly_token

  # advisor validations
  validates :email, :presence => true
  validates_format_of :email, :with => User::EMAIL_REGEX

  validates :password, :presence => true,
                       :confirmation => true,
                       :length => { :within => 8..40 }

  validates :password_confirmation, :presence => true, :on => :create

  # uniqueness validation doesn't work in form objects, so it is custom
  validate  :email_is_unique

  def get_advisor
    @advisor if @advisor.persisted?
  end

  private

  def email_is_unique
    return unless email.present?

    if User.where(email: email).exists?
      errors.add(:email, "This email is already in use")
    end
  end

  def persist!
    @advisor = User.new(attributes)
    @advisor.app_type = User::WEB_APP
    @advisor.consumer_account_type_id = ConsumerAccountType::BUSINESS #For now all signups via web app will be considered Business type, so their mobile app is configured for Business account
    if @advisor.save
      UserFolderSetting.setup_folder_setting_for_user(@advisor)
      true
    else
      false
    end
  end

end
