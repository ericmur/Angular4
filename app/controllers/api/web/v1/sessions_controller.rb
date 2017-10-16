class Api::Web::V1::SessionsController < Api::Web::V1::ApiController
  skip_before_action :check_authentication, only: [:create]

  def create
    email = params[:session][:email]
    password = params[:session][:password]

    advisor = User.find_by(email: email)
    if advisor
      if advisor.valid_password? password
        advisor.update(authentication_token: Devise.friendly_token)
        advisor.update_auth_encrypted_private_key(password)
        UserStatisticService.new(advisor).set_last_logged_in_web_app
        render status: 200, json: advisor, scope: advisor, serializer: Api::Web::V1::AdvisorSerializer
      else
        render status: 401, json: { message: 'Invalid password.' }
      end
    else
      render status: 401, json: { message: 'Invalid email.' }
    end
  end

  def destroy
    current_advisor.authentication_token = nil
    current_advisor.current_workspace_id = nil
    current_advisor.auth_token_private_key = nil
    current_advisor.current_workspace_name = nil
    current_advisor.save!
    render status: 204, json: nil
  end
end
