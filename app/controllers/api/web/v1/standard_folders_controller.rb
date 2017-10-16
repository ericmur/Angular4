class Api::Web::V1::StandardFoldersController < Api::Web::V1::ApiController
  before_action :set_standard_folder_categories, only: :index
  before_action :set_standard_folder, only: :show

  def index
    render status: 200, json: @standard_folder_categories, each_serializer: ::Api::Web::V1::StandardFolderSerializer
  end

  def show
    render status: 200, json: @standard_folder, serializer: ::Api::Web::V1::StandardFolderSerializer
  end

  private

  def set_standard_folder_categories
    @standard_folder_categories = ::Api::Web::V1::StandardFoldersQuery
      .new(current_advisor, params).get_categories
  end

  def set_standard_folder
    @standard_folder = ::Api::Web::V1::StandardFoldersQuery
      .new(current_advisor, params).get_standard_folder
  end
end
