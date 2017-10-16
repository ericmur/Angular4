class Api::Web::V1::AdvisorSetCredentialsForm < Api::Web::V1::BaseForm
  mimic :advisor

  attribute :pincode, String
  attribute :unverified_email, String
  attribute :password, String
  attribute :password_confirmation, String

  validates :id, presence: true
  validates :pincode, presence: true

  validates_format_of :unverified_email, with: User::EMAIL_REGEX, if: 'unverified_email.present?'
  validate  :email_is_unique

  validates :password, presence: true,
                       confirmation: true,
                       length: { within: 8..40 }

  validates :password_confirmation, presence: true

  def email_is_unique
    return unless unverified_email.present?

    if User.where(email: unverified_email).where.not(id: id).exists?
      errors.add(:email, "This email is already in use")
    end
  end

  def to_model
    User.find_by(id: id)
  end

  def persist!
    advisor = self.to_model
    advisor.update_password_encrypted_private_key(pincode, password)
    advisor.password = password
    if unverified_email.present?
      if advisor.email.blank? or advisor.email_confirmed_at.nil?
        advisor.email = unverified_email
        advisor.unverified_email = unverified_email
      else
        advisor.unverified_email = unverified_email
      end
    end
    advisor.save
  end

end
