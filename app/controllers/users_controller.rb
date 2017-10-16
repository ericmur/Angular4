class UsersController < ApplicationController
  skip_before_action :doorkeeper_authorize!, except: [:show, :set_notifications_read_at, :set_messages_read_at]
  skip_before_action :confirm_phone!, except: [:show, :set_notifications_read_at, :set_messages_read_at]
  skip_before_action :confirm_device_uuid!, except: [:show, :set_notifications_read_at, :set_messages_read_at]
  before_action :load_user_by_phone, only: [:authenticate_password, :create_pin, :authenticate_phone_or_device, :resend_phone_confirmation_code, :resend_new_device_code]
  before_action :verify_valid_password, only: [:authenticate_password, :create_pin]

  def create
    @user = User.new(user_params)
    @user.app_type = User::MOBILE_APP
    if params[:referral_code].present?
      referral_code = ReferralCode.where(code: params[:referral_code]).first
      unless referral_code == nil
        @user.referrer = referral_code.user
      end
    end
    respond_to do |format|
      if @user.save
        format.json { render :json => @user, serializer: ConsumerSerializer, :status => :ok }
      else
        @user.clean_up_pins
        format.json { render :json => { :errors => @user.errors.full_messages }, :status => :not_acceptable }
      end
    end
  end

  def show
    @user = User.find(params[:id])
    respond_to do |format|
      format.json { render json: @user, serializer: UserSerializer, root: 'user', status: :ok }
    end
  end

  def set_notifications_read_at
    @user = current_user
    @user.last_time_notifications_read_at = Time.zone.now
    @user.save
    respond_to do |format|
      format.json { render nothing: true, status: :accepted }
    end
  end

  def set_messages_read_at
    @chat = Chat.find(params[:chat_id])
    @chats_users_relation = @chat.chats_users_relations.where(chatable: current_user).first
    @chats_users_relation.last_time_messages_read_at = Time.zone.now
    @chats_users_relation.save
    respond_to do |format|
      format.json { render nothing: true, status: :accepted }
    end
  end

  def check
    users = User.where(phone_normalized: PhonyRails.normalize_number(params[:phone].try(:strip), :country_code => User::PHONE_COUNTRY_CODE))
    c = users.count
    respond_to do |format|
      if c == 1
        user = users.first
        unless user.has_pin?
          if !user.confirmed_phone?
            user.resend_phone_confirmation_code
          elsif !user.has_device_confirmed?(params[:device_uuid])
            user.recreate_device(params[:device_name], params[:device_uuid])
          end
        end

        format.json { render json: user, device_uuid: params[:device_uuid], status: :im_used }
      elsif c > 1
        raise "Multiple consumers with phone: #{params[:phone]} exist in the system"
      else
        format.json { render :nothing => true, :status => :accepted }
      end
    end
  end

  def authenticate_phone_or_device
    if !@user.confirmed_phone?
      confirm_phone_number
    elsif !@user.has_device_confirmed?(params[:device_uuid])
      confirm_device_uuid
    else
      respond_to do |format|
        format.json { render status: :not_acceptable, json: { errors: ["Invalid Request."] } }
      end
    end
  end

  def authenticate_password
    respond_to do |format|
      format.json { render nothing: true, status: :accepted }
    end
  end

  def resend_phone_confirmation_code
    respond_to do |format|
      if @user.resend_phone_confirmation_code
        format.json { render :nothing => true }
      else
        format.json { render :json => { :errors => @user.errors.full_messages }, :status => :not_acceptable }
      end
    end
  end

  def resend_new_device_code
    @device = @user.devices.where(:device_uuid => params[:device][:device_uuid]).first
    respond_to do |format|
      if @device.resend_new_device_code
        format.json { render :nothing => true }
      else
        format.json { render :json => { :errors => @device.errors.full_messages }, :status => :not_acceptable }
      end
    end
  end

  def create_pin
    @user.pin = params[:pin].to_s.strip
    @user.pin_confirmation = params[:pin_confirmation].to_s.strip
    @user.app_type = User::MOBILE_APP
    pgp = Encryption::Pgp.new(:private_key => @user.password_private_key, :password => @user.password_hash(params[:password]))
    new_pgp = Encryption::Pgp.new(:private_key => pgp.unencrypted_private_key, :password => @user.password_hash(@user.pin))
    @user.private_key = new_pgp.private_key

    respond_to do |format|
      if @user.save
        format.json { render nothing: true, status: :accepted }
      else
        format.json { render nothing: true, status: :forbidden }
      end
    end
  end

  def forgot_pin
    c = User.where(phone: params[:phone]).first
    if c
      c.send_forget_pin_code
      respond_to do |format|
        format.json { render :json => { :user_id => c.id }, :status => :ok }
      end
    else
      respond_to do |format|
        format.json { render :json => { :errors => ["Could not find an account with that phone number."] }, :status => :not_acceptable }
      end
    end
  end
  
  private
  def user_params
    params.require(:user).permit(:email, :pin, :pin_confirmation, :phone)
  end

  def load_user
    @user = User.where(:id => params[:id]).first
  end

  def load_user_by_phone
    phone_normalized = PhonyRails.normalize_number(params[:phone].try(:strip), country_code: User::PHONE_COUNTRY_CODE)
    users = User.where(phone_normalized: phone_normalized)
    @user = users.first

    unless @user.present?
      respond_to do |format|
        format.json { render json: { errors: ['Failed to authenticate account.'] }, status: :forbidden }
      end
    end
  end

  def verify_valid_password
    unless @user.valid_password?(params[:password].strip)
      respond_to do |format|
        format.json { render json: { errors: ['Failed to authenticate account.'] }, status: :forbidden }
      end
    end
  end

  def confirm_phone_number
    if @user.phone_confirmation_token == params[:token]
      respond_to do |format|
        if @user.confirm_phone
          @user.add_device!(params[:device_name], params[:device_uuid])
          format.json { render nothing: true, status: :ok }
        else
          format.json { render status: :not_acceptable, json: { errors: @user.errors.full_messages } }
        end
      end
    else
      respond_to do |format|
        format.json { render status: :not_acceptable, json: { errors: ["Invalid Code. Please try again."] } }
      end
    end
  end

  def confirm_device_uuid
    @device = @user.devices.where(device_uuid: params[:device_uuid]).first
    if @device.confirmation_token == params[:token]
      respond_to do |format|
        if @device.confirm
          format.json { render nothing: true, status: :ok }
        else
          format.json { render status: :not_acceptable, json: { errors: @device.errors.full_messages } }
        end
      end
    else
      respond_to do |format|
        format.json { render status: :not_acceptable, json: { errors: ["Invalid Code. Please try again."] } }
      end
    end
  end
end
