class CloudServiceAuthorizationsController < ApplicationController
  before_filter :load_cloud_service, :only => [:create]
  
  def create
    if @cloud_service.id == CloudService.find_by_name(CloudService::GOOGLE_DRIVE).id
      GoogleDriveRefreshTokenRetrieverJob.perform_later(params[:cloud_service_authorization][:auth_code], params[:cloud_service_authorization][:uid], current_user.id, params[:cloud_service_authorization][:path], params[:cloud_service_authorization][:path_display_name])
      respond_to do |format|
        format.json { render json: { success: true } }
      end
    else
      if service_authorization = current_user.cloud_service_authorizations.where(:cloud_service_id => @cloud_service.id, :uid => params[:cloud_service_authorization][:uid]).first
        service_authorization.token = params[:cloud_service_authorization][:token]
      else
        service_authorization = current_user.cloud_service_authorizations.build(cloud_service_authorization_params.reject { |k, v| k.to_s == "path" })
      end
    
      if service_authorization.save
        cloud_service_path = current_user.find_or_create_cloud_service_path(:cloud_service_authorization_id => service_authorization.id, :path => params[:cloud_service_authorization][:path])
        cloud_service_path.sync_data
        
        respond_to do |format|
          format.json { render json: { success: true } }
        end
      else
        respond_to do |format|
          puts service_authorization.errors.full_messages.inspect
          format.json { render :json => { :errors => service_authorization.errors.full_messages }, :status => :not_acceptable }
        end
      end
    end
  end

  private

  def load_cloud_service
    @cloud_service = CloudService.find_by_id(params[:cloud_service_authorization][:cloud_service_id])
  end

  def cloud_service_authorization_params
    if @cloud_service.id == CloudService.find_by_name(CloudService::GOOGLE_DRIVE).id
      params.require(:cloud_service_authorization).permit(:cloud_service_id,
                                                          :uid,
                                                          :auth_code,
                                                          :path,
                                                          :path_display_name)
    else
      params.require(:cloud_service_authorization).permit(:cloud_service_id,
                                                          :uid,
                                                          :token,
                                                          :path)
    end
  end
end
