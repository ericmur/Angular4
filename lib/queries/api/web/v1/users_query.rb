class Api::Web::V1::UsersQuery

  def initialize(params)
    @phone = params[:phone]
  end

  def search_by_phone
    User.where(
      phone_normalized: PhonyRails.normalize_number(
        @phone.try(:strip),
        country_code: User::PHONE_COUNTRY_CODE
      )
    ).first
  end

end
