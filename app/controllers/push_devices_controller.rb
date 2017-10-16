class PushDevicesController < ApplicationController
  # Note: This action requested inside app initialization
  # Make sure that it doesn't response back error even though validation failing
  def create
    push_device = PushDevice.find_by_device_uuid(params[:device_uuid])

    if push_device.nil?
      push_device = PushDevice.new
      push_device.device_uuid = params[:device_uuid]
    end

    push_device.device_token = params[:device_token]
    push_device.user_id = current_user.id
    push_device.save

    respond_to do |format|
      format.json { render :json => {}, :status => :ok }
    end
  end

end
