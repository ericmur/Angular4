class Api::Web::V1::PhoneTokenService

  def initialize(current_advisor, params)
    @advisor     = current_advisor
    @resend_code = params[:resend_code]

    set_advisor_params(params[:advisor]) if params[:advisor]

    @errors = []
  end

  def set_advisor_params(params)
    @token = params[:token]

    @confirmation_type   = params[:type]
    @change_phone_number = params[:change_phone_number]
  end

  def set_confirmation_token
    if @confirmation_type == 'web'
      set_web_phone_confirmation_token
    else
      set_phone_confirmation_token
    end
  end

  def get_errors
    @errors
  end

  def send_phone_token
    return resend_phone_token if @resend_code

    send_first_time_phone_token
  end

  private

  def set_web_phone_confirmation_token
    if @advisor.web_phone_confirmation_token == @token
      @advisor.confirm_phone(type: 'web')
    else
      add_error
    end
  end

  def set_phone_confirmation_token
    if @advisor.phone_confirmation_token == @token
      @change_phone_number ? @advisor.set_verified_phone_number : @advisor.confirm_phone
    else
      add_error
    end
  end

  def add_error
    @errors << "Invalid Code. Please try again."
  end

  def resend_phone_token
    return @advisor.resend_phone_confirmation_code if @advisor.web_app_is_set_up?

    @advisor.resend_phone_confirmation_code(type: 'web')
  end

  def send_first_time_phone_token
    return @advisor.send_phone_token if @advisor.web_app_is_set_up?

    @advisor.send_phone_token(type: 'web')
  end

end
