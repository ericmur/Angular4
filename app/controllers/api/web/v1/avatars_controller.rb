class Api::Web::V1::AvatarsController < Api::Web::V1::ApiController

  def create
    if params[:avatar_type] == 'user'
      avatar = Api::Web::V1::AvatarBuilder.new(current_advisor, params).create_avatar
    else
      avatar = Api::Web::V1::AvatarBuilder.new(current_advisor.businesses.last, params).create_avatar
    end
    if avatar.persisted?
      render status: 201, json: avatar
    else
      render status: 422, json: avatar.errors
    end
  end

  def complete_upload
    if params[:avatar_type] == 'user'
      avatar = Api::Web::V1::AvatarBuilder.new(current_advisor, avatar_params).complete_avatar_upload
    else
      avatar = Api::Web::V1::AvatarBuilder.new(current_advisor.businesses.last, avatar_params).complete_avatar_upload
    end
    if avatar.errors.empty? && avatar.complete_upload! && avatar.save
      render status: 200, json: avatar
    else
      render status: 422, json: avatar.errors
    end
  end

  private

  def avatar_params
    params.require(:avatar).permit(:s3_object_key)
  end

end
