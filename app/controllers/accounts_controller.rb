class AccountsController < ApplicationController
  before_action :load_user_password_hash, :only => [:allow_access]
  skip_before_action :confirm_device_uuid!, :only => [:confirm_phone_number, :add_device, :confirm_device, :resend_phone_confirmation_code, :resend_new_device_code, :update_pin] #Skipping for update_pin too because when resetting pin during forgot_pin flow, device might not be valid because it might have been deleted from our side to show them walkthrough flow
  skip_before_action :confirm_phone!, :only => [:confirm_phone_number, :resend_phone_confirmation_code]
  before_filter :check_device_existence, :only => [:add_device]
  before_filter :pin_required, :only => [:show, :validate_pin, :update_pin]
  before_filter :private_key_required, :only => [:update_pin]

  def show
    #Show documents and password_hash for consumer login
    current_user.update_app_version
    VerifyDocumentCacheJob.perform_later(current_user.id)
    respond_to do |format|
      format.json { render :json => current_user, :serializer => ConsumerSerializer, :status => :ok }
    end
  end

  def check_credit_limit
    current_usage = params[:current_usage].to_i
    available = current_user.user_credit.has_available_fax_credit?(current_usage)
    render json: current_user.user_credit, serializer: ::Api::Mobile::V2::UserCreditSerializer, current_usage: current_usage, available: available
  end

  def download_exhausted
    if Rails.env.production?
      DownloadExhaustedNotifierJob.perform_later(params[:id], params[:klass])
      AdminMailer.download_exhausted(params[:id], params[:klass]).deliver_later
    end

    respond_to do |format|
      format.json { render json: { status: true } }
    end
  end

  def quick_refresh
    respond_to do |format|
      format.json { render :json => current_user, serializer: QuickConsumerSerializer, :status => :ok }
    end
  end

  def update_pin
    current_user.app_type = User::MOBILE_APP
    if current_user.update_pin(params[:pin], params[:private_key])
      respond_to do |format|
        format.json { render :json => current_user, :serializer => ConsumerSerializer, :status => :ok }
      end
    else
      respond_to do |format|
        format.json { render :json => { :errors => current_user.errors.full_messages }, :status => :unprocessable_entity }
      end
    end
  end

  def validate_pin
    if current_user.valid_pin?(params[:pin])
      respond_to do |format|
        format.json { render :nothing => true, :status => :ok }
      end
    else
      respond_to do |format|
        format.json { render :json => { :errors => ["Invalid PIN. Please try again."] }, :status => :not_acceptable }
      end
    end
  end

  def resend_phone_confirmation_code
    @user = current_user
    respond_to do |format|
      if @user.resend_phone_confirmation_code
        format.json { render :nothing => true }
      else
        format.json { render :json => { :errors => @user.errors.full_messages }, :status => :not_acceptable }
      end
    end
  end

  def resend_new_device_code
    @device = self.current_user.devices.where(:device_uuid => params[:device][:device_uuid]).first
    respond_to do |format|
      if @device.resend_new_device_code
        format.json { render :nothing => true }
      else
        format.json { render :json => { :errors => @device.errors.full_messages }, :status => :not_acceptable }
      end
    end
  end

  def confirm_phone_number
    @user = current_user
    if @user.phone_confirmation_token == params[:token]
      respond_to do |format|
        if @user.confirm_phone
          @user.add_device!(params[:name], params[:device_uuid])
          format.json { render :json => @user, :serialize => ConsumerSerializer, :status => :ok }
        else
          format.json { render :json => { :errors => @user.errors.full_messages }, :status => :not_acceptable }
        end
      end
    else
      respond_to do |format|
        format.json { render :json => { :errors => ["Invalid Code. Please try again."] }, :status => :not_acceptable }
      end
    end
  end

  def add_device
    @device = self.current_user.devices.build(device_params)
    respond_to do |format|
      if @device.save
        format.json { render :json => self.current_user, :status => :ok }
      else
        format.json { render :json => { :errors => @device.errors.full_messages }, :status => :not_acceptable }
      end
    end
  end

  def confirm_device
    @device = self.current_user.devices.where(:device_uuid => params[:device][:device_uuid]).first
    if @device.confirmation_token == params[:device][:token]
      respond_to do |format|
        if @device.confirm
          format.json { render :json => self.current_user, :status => :ok }
        else
          format.json { render :json => { :errors => @device.errors.full_messages }, :status => :not_acceptable }
        end
      end
    else
      respond_to do |format|
        format.json { render :json => { :errors => ["Invalid Code. Please try again."] }, :status => :not_acceptable }
      end
    end
  end

  def allow_access
    ua = self.current_user.user_accessors.build(access_params)
    if ua.save_with_keys
      respond_to do |format|
        format.json { render :json => ua }
      end
    else
      respond_to do |format|
        format.json { render :json => { :errors => ua.errors.full_messages }, :status => :not_acceptable }
      end
    end
  end

  def remove_access
    ua = self.current_user.user_accessors.where(:accessor_id => params[:accessor_id]).first
    if ua.remove(params[:remove_keys])
      respond_to do |format|
        format.json { render :json => { }, status: :no_content }
      end
    else
      respond_to do |format|
        format.json { render :json => { :errors => ua.errors.full_messages }, :status => :not_acceptable }
      end
    end
  end

  def update_email
    @user = User.find(current_user.id)
    if @user.email.nil?
      @user.email = params[:email]
    end

    @user.unverified_email = params[:email]

    respond_to do |format|
      if @user.save
        @user.generate_email_confirmation_token
        format.json { render :nothing => true }
      else
        format.json { render :json => { :errors => @user.errors.full_messages }, :status => :unprocessable_entity }
      end
    end
  end

  def check_limit
    respond_to do |format|
      if params[:new_files_size].present? && params[:new_pages_count].present?
        unless current_user.has_available_storage?(params[:new_files_size], params[:new_pages_count])
          SlackHelper.ping({ channel: "##{Rails.env}", username: "AccountLimit", message: "User #{current_user.id} exceeds storage quota. Total Storage: #{current_user.total_storage_size}. Total Pages: #{current_user.total_pages_count}" }) if (Rails.env.production? or Rails.env.staging?)
          format.json { render :json => { :errors =>  ["You have exceeded your current limit of 2GB worth of scans. Please contact Docyt support to get it increased."] }, :status => :unprocessable_entity }
        else
          format.json { render :json => current_user, serializer: AccountLimitSerializer }
        end
      else
        format.json { render :json => current_user, serializer: AccountLimitSerializer }
      end
    end
  end

  def update
    user = User.find(current_user.id)
    user.parse_fullname(params[:fullname]) if params[:fullname].present?
    if params[:consumer_account_type_id]
      user.consumer_account_type_id = params[:consumer_account_type_id]
      UserFolderSetting.setup_folder_setting_for_user(user)
    end

    if params[:email]
      if user.email.nil?
        user.email = params[:email]
      end
      user.unverified_email = params[:email]
    end

    respond_to do |format|
      if user.save
        if params[:email]
          user.generate_email_confirmation_token
        end
        format.json { render json: {
          first_name: user.first_name,
          middle_name: user.middle_name,
          last_name: user.last_name,
        }, status: :ok }
      else
        format.json { render json: { errors: user.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  private

  def account_params
    params.require(:pin)
  end

  def access_params
    params.permit(:accessor_id)
  end

  def device_params
    params.require(:device).permit(:device_uuid, :name)
  end

  def check_device_existence
    if @device = self.current_user.devices.where(:device_uuid => params[:device][:device_uuid]).first
      respond_to do |format|
        format.json { render :json => self.current_user, :status => :ok }
      end
    end
  end

  def pin_required
    if params[:pin].blank?
      respond_to do |format|
        format.json { render :json => { :errors => ["Pin is required"] }, :status => :not_acceptable }
      end
    end
  end

  def private_key_required
    if params[:private_key].blank?
      respond_to do |format|
        format.json { render :json => { :errors => ["Private key is required"] }, :status => :not_acceptable }
      end
    end
  end
end
