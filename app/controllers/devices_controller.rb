class DevicesController < ApplicationController

  def index
    devices = self.current_user.devices
    respond_to do |format|
      format.json { render :json => devices }
    end
  end

  def destroy
    device = self.current_user.devices.find(params[:id])
    respond_to do |format|
      if device.destroy
        format.json { render :json => device, :status => :ok }
      else
        format.json { render :json => { :errors => device.errors.full_messages }, :status => :not_acceptable }
      end
    end
  end
end