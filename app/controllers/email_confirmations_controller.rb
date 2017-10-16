class EmailConfirmationsController < ApplicationController
  layout 'simple'
  skip_before_action :doorkeeper_authorize!, except: [:resend_confirmation]
  skip_before_action :confirm_phone!, except: [:resend_confirmation]
  skip_before_action :confirm_device_uuid!, except: [:resend_confirmation]
  
  def new
  end

  def resend_confirmation
    @user = current_user
    @user.generate_email_confirmation_token
    respond_to do |format|
      format.json { render json: {  }, status: :ok }
    end
  end

  def confirm
    user = User.find_by(email_confirmation_token: params[:token])
    if User.verify_email_token(params[:token])
      user.authentication_token = nil
      user.save!
        
      if user.advisor?
        respond_to do |format|
          format.html { redirect_to "/sign_in?confirmed=true" }
          format.json { render json: {  }, status: :ok }
        end
      else
        respond_to do |format|
          format.html do
            @verified = true
            flash[:notice] = I18n.t('email_confirmation.messages.phone_successful')
            render action: 'completed'
          end
        end
      end
    else
      error_message = I18n.t('email_confirmation.messages.resend')
      respond_to do |format|
        format.html { redirect_to new_email_confirmation_path, notice: error_message }
        format.json { render json: { errors: [error_message] }, status: :not_acceptable }
      end
    
    end
  end

  def completed
  end

end
