class Api::Web::V1::AvatarBuilder

  def initialize(advisor, avatar_params)
    @params = avatar_params
    @advisor = advisor
    @avatar = get_avatar
  end

  def create_avatar
    @avatar.destroy unless @avatar.nil?
    @advisor.create_avatar
  end

  def complete_avatar_upload
    if @params['s3_object_key'].blank?
      @avatar.errors.add(:s3_object_key, 'S3 file path is not set')
    else
      @avatar.s3_object_key = @params['s3_object_key']
    end

    @avatar
  end

  private

  def get_avatar
    @advisor.avatar
  end

end
