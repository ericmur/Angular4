class Api::Mobile::V2::StandardCategoriesController < Api::Mobile::V2::ApiController
  def create
    @standard_category = StandardCategory.new(standard_category_params)
    @standard_category.consumer_id = current_user.id
    if @standard_category.save
      render status: 200, json: @standard_category, serializer: ::Api::Mobile::V2::StandardCategorySerializer, root: 'standard_category'
    else
      render status: 422, json: { errors: @standard_category.errors.full_messages }
    end
  end

  private

  def standard_category_params
    params.require(:standard_category).permit(:name)
  end
end