class Api::Web::V1::AdvisorsController < Api::Web::V1::ApiController
  skip_before_action :check_authentication, only: [:create, :get_advisor_types, :search, :send_phone_token, :confirm_phone_number, :confirm_pincode, :confirm_credentials]

  def create
    form = ::Api::Web::V1::AdvisorCreateForm.new(advisor_params)

    if form.save
      advisor = form.get_advisor
      render status: 201, json: advisor, scope: advisor, serializer: ::Api::Web::V1::AdvisorSerializer
    else
      render status: 422, json: form.errors
    end
  end

  def update
    form = ::Api::Web::V1::AdvisorUpdateForm.from_params(params)
    if form.save
      form.to_model.generate_email_confirmation_token if params[:advisor][:unverified_email]
      form.to_model.send_phone_token_for_verified_new_phone_number if params[:advisor][:unverified_phone]
      render status: 200, json: form.to_model, serializer: ::Api::Web::V1::AdvisorSerializer
    else
      render status: 422, json: form.errors
    end
  end

  def get_current_advisor
    render status: 200, json: current_advisor, scope: current_advisor, serializer: ::Api::Web::V1::AdvisorSerializer
  end

  def get_advisor_types
    render status: 200, json: StandardCategory.where.not(:id => StandardCategory::DOCYT_SUPPORT_ID),
      root: :standard_categories
  end

  def search
    @user = Api::Web::V1::UsersQuery.new(search_params).search_by_phone

    if @user
      render status: 200, json: @user, scope: @user, serializer: ::Api::Web::V1::AdvisorSerializer
    else
      render status: 404, json: {}
    end
  end

  def add_phone_number
    if current_advisor.update(phone: params[:phone])
      current_advisor.send_phone_token
      render status: 200, json: current_advisor, serializer: ::Api::Web::V1::AdvisorSerializer
    else
      render status: :not_acceptable, json: { error_message: current_advisor.errors }
    end
  end

  def confirm_phone_number
    advisor = set_advisor
    service = Api::Web::V1::PhoneTokenService.new(advisor, params)
    service.set_confirmation_token

    if service.get_errors.empty?
      render status: 200, json: advisor, serializer: ::Api::Web::V1::AdvisorSerializer
    else
      render status: 406, json: { error_message: "Invalid Code. Please try again." }
    end
  end

  def confirm_pincode
    advisor = User.find_by_id(advisor_params[:id])
    if advisor.valid_pin?(advisor_params[:pincode])
      render status: 200, json: advisor, serializer: ::Api::Web::V1::AdvisorSerializer,
        pincode_status: { valid_pin: true }, meta_key: :pincode_status
    else
      render status: 406, json: { error_message: "Invalid PIN. Please try again." }
    end
  end

  def confirm_credentials
    form = ::Api::Web::V1::AdvisorSetCredentialsForm.from_params(params)

    if form.save
      form.to_model.generate_email_confirmation_token if params[:advisor][:unverified_email]
      render status: 200, json: { message: 'Sign In with the account you have just setup' }
    else
      render status: 422, json: form.errors
    end
  end

  def resend_email_confirmation
    current_advisor.generate_email_confirmation_token
    render status: 200, json: {}
  end

  def send_phone_token
    advisor = User.find_by_id(params[:user_id])

    Api::Web::V1::PhoneTokenService.new(advisor, params).send_phone_token

    render status: 200, json: {}
  end

  private

  def advisor_params
    params.require(:advisor).permit(:id, :email, :password, :password_confirmation,
                                    :standard_category_id, :phone, :token, :pincode)
  end

  def search_params
    params.require(:search).permit(:phone)
  end

  def set_advisor
    if auth_token and auth_token != "null" and auth_token != "undefined"
      check_authentication
      current_advisor
    else
      User.find_by_id(params[:advisor][:id])
    end
  end

end
