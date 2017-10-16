class Api::Web::V1::StandardFolderSerializer < ActiveModel::Serializer
  attributes :id, :name, :type, :category, :rank, :description, :category,
  :documents_count, :icon_name_2x, :icon_name_3x, :icon_name_1x,
  :icon_url

  def documents_count
    return nil unless object.respond_to?(:category_documents_count)

    object.category_documents_count
  end

  def icon_url
    screen_scale = 3
    icon_name  = object.read_attribute("icon_name_#{screen_scale}x")

    return nil if icon_name.blank?
    ActionController::Base.helpers.asset_url("categories/#{icon_name}")
  end
end
