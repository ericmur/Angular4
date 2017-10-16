class Api::Web::V1::AdvisorUpdateForm < Api::Web::V1::BaseForm
  mimic :advisor

  attribute :first_name, String
  attribute :middle_name, String
  attribute :last_name, String
  attribute :email, String
  attribute :unverified_email, String
  attribute :unverified_phone, String
  attribute :current_password, String
  attribute :password, String
  attribute :password_confirmation, String
  attribute :consumer_account_type_id, Integer
  attribute :standard_category_id, Integer
  attribute :current_workspace_id, Integer
  attribute :current_workspace_name, String

  validates :id, presence: true
  validate  :advisor_existence

  validates_format_of :unverified_email, :with => User::EMAIL_REGEX, if: 'unverified_email.present?'
  validate  :email_is_unique

  validates_plausible_phone :unverified_phone
  validate  :phone_is_unique

  validates :current_password, presence: true, if: :password?
  validate  :authenticated, if: :password?

  validates :password,  presence: true,
                        confirmation: true,
                        length: { within: 8..40 },
                        allow_blank: true

  def password?
    password.present?
  end

  def advisor_existence
    unless User.exists? id
      errors.add(:id, "Invalid advisor id")
    end
  end

  def authenticated
    unless User.find_by(id: id).valid_password? current_password
      errors.add(:password, "Invalid password")
    end
  end

  def email_is_unique
    return unless unverified_email.present?

    if User.where(email: unverified_email).where.not(id: id).exists?
      errors.add(:email, "This email is already in use")
    end
  end

  def phone_is_unique
    return unless unverified_phone.present?

    if User.where(phone: unverified_phone).where.not(id: id).exists?
      errors.add(:phone, "This phone is already in use")
    end
  end

  def attributes
    super.except(:current_password).reject{ |k, v| v.nil? }
  end

  def to_model
    User.find_by(id: id)
  end

  def persist!
    advisor = self.to_model
    if password?
      advisor.password_updated_at = Time.now
      advisor.set_password_private_key_using_new_password(password)
    end
    advisor.update(attributes)
  end
end
