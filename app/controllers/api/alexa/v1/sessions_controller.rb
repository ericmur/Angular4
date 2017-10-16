class Api::Alexa::V1::SessionsController < Api::Alexa::V1::ApiController
  skip_before_action :confirm_device_uuid!, :only => [:add_device, :confirm_device]
  before_filter :check_device_existence, :only => [:add_device]
  before_action :require_alexa_passcode_setup!, :except => [:add_device, :confirm_device, :set_passcode]

  def welcome
    respond_to do |format|
      format.json { render :nothing => true, :status => :ok }
    end
  end
  
  def add_device
    @device = self.current_user.devices.build(device_params)
    respond_to do |format|
      if @device.save
        format.json { render :nothing => true, :status => :ok }
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
          format.json { render :nothing => true, :status => :ok }
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
  
  def verify_passcode
    @device = self.current_user.devices.where(:device_uuid => params[:device_uuid]).first
    respond_to do |format|
      if !params[:pass_code].blank? and @device.decrypt_pass_code == params[:pass_code]
        docyt_bot_session = DocytBotSession.create_with_token!
        format.json { render :json => docyt_bot_session, :status => :ok }
      else
        format.json { render :json => { :errors => ["Invalid passcode. Please try again."] }, status => :not_acceptable }
      end
    end
  end

  def set_passcode
    @device = self.current_user.devices.where(:device_uuid => params[:device_uuid]).first
    @device.input_pass_code = params[:pass_code]
    respond_to do |format|
      if @device.save
        format.json { render :nothing => true, :status => :ok }
      else
        format.json { render :json => { :errors => ["Could not set passcode. Please try again."] }, :status => :not_acceptable }
      end
    end
  end

  def destroy
    docyt_bot_session = DocytBotSession.find_by_session_token(params[:session_token])
    docyt_bot_session.destroy if docytbot_session
    respond_to do |format|
      format.json { render :nothing => true, :status => :ok }
    end
  end
  
  private

  def require_alexa_passcode_setup!
    if current_user and current_user.confirmed_devices.where(:device_uuid => params[:device_uuid]).first.pass_code.nil?
      respond_to do |format|
        format.json { render :json => { :errors => ["Alexa passcode is not setup"] }, status: :forbidden }
      end
    end
  end

  def device_params
    params.require(:device).permit(:device_uuid, :name)
  end

  def check_device_existence
    if @device = self.current_user.devices.where(:device_uuid => params[:device][:device_uuid]).first
      @device.resend_new_device_code if @device.confirmed_at.nil?
      
      respond_to do |format|
        format.json { render :json => self.current_user, :status => :ok }
      end
    end
  end
end
