class AvatarsController < ApplicationController
  before_action :load_avatarable
  before_action :build_or_recreate, only: [:create]
  
  def create
    respond_to do |format|
      if @avatar.save
        format.json { render json: @avatar }
      else
        format.json { render json: @avatar.errors.full_messages, status: :unprocessable_entity }
      end
    end
  end

  def complete_upload
    @avatar.update_column(:s3_object_key, params[:s3_object_key])
    respond_to do |format|
      if @avatar.complete_upload!
        format.json { render json: @avatar }
      else
        format.json { render json: @avatar.errors.full_messages, status: :unprocessable_entity }
      end
    end
  end

  private

  def build_or_recreate
    if @avatar.nil?
      @avatar = @avatarable.build_avatar 
    else
      @avatar.destroy
      @avatar = @avatarable.build_avatar
    end
  end

  def load_avatarable
    klass = params[:avatarable_type].to_s
    @avatarable = klass.constantize.find(params[:avatarable_id])
    @avatar = @avatarable.avatar
  end

end