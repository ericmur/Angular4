class Api::Mobile::V2::FieldDescriptionSerializer < ActiveModel::Serializer
  attributes :id, :name, :data_type, :is_system

  def is_system
    std_doc = StandardDocument.find_by_id(object.standard_document_id)
    return std_doc && std_doc.consumer_id.blank?
  end

  def data_type
    if ["due_date", "expiry_date"].include?(object.data_type)
      if Rails.mobile_app_version and Gem::Version.new(Rails.mobile_app_version) >= Gem::Version.new("1.1.0")
        object.data_type
      else
        "date"
      end
    elsif object.data_type == "array"
      if Rails.mobile_app_version and Gem::Version.new(Rails.mobile_app_version) >= Gem::Version.new("1.2.1")
        object.data_type
      else
        "string"
      end
    else
      object.data_type
    end
  end
end
