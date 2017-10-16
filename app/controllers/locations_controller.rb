class LocationsController < ApplicationController
  def create
    @location = current_user.locations.build(location_params)
    respond_to do |format|
      if @location.save
        CleanupUserLocationsJob.perform_later(current_user.id)
        format.json { render json: {  }, status: :ok }
      else
        format.json { render json: { errors: @location.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  private

  def location_params
    params.require(:location).permit(:latitude, :longitude)
  end
end