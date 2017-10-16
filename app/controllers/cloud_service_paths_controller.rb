class CloudServicePathsController < ApplicationController
  def create
    service_path = consumer.cloud_service_paths.build(cloud_service_path_params)
    if service_path.save
      respond_to do |format|
        format.json { render json: { success: true } }
      end
    else
      respond_to do |format|
        format.json { render :json => { :errors => service_path.errors.full_messages }, :status => :not_acceptable }
      end
    end
  end

  def destroy
    consumer.cloud_service_paths.find(params[:id]).destroy
    respond_to do |format|
      format.json { render json: { success: true } }
    end
  end

  private

  def cloud_service_path_params
    params
      .require(:cloud_service_path)
      .permit(
              :cloud_service_id,
              :path,
              :path_display_name
      )
  end
end
