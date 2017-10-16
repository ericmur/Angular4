class BaseDocumentFieldSerializer < ActiveModel::Serializer
  attributes :id, :name, :data_type, :value, :field_value_id, :min_year, :max_year, :type, :suggestions,
    :document_id, :notify, :notification_level, :created_by_user_id, :encryption, :is_standard_document_field,
    :data_type_values

  def id
    object.field_id
  end

  def data_type_values
    if Rails.mobile_app_version and Gem::Version.new(Rails.mobile_app_version) >= Gem::Version.new("1.2.2")
      object.data_type_values.reject { |v| v.to_s.downcase.match('other') }
    else
      object.data_type_values
    end
  end

  def skip_secure_value?
    scope[:skip_secure_value] == true
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

  def type
    if Rails.mobile_app_version and Gem::Version.new(Rails.mobile_app_version) >= Gem::Version.new("1.1.7")
      object.type
    elsif BaseDocumentField::ALERT_DATA_TYPES.include?(object.data_type)
      'StandardDateDocumentField'
    else
      'DocumentField'
    end
  end

  def value
    if object.encryption? && skip_secure_value?
      return nil
    end

    field_value = field_value_obj
    if field_value
      field_value.user_id = scope[:current_user].id #Needed to call field_value.decrypt_value
    end
    field_value ? field_value.field_value : nil
  end

  def notification_level
    field_value = field_value_obj
    field_value ? field_value.notification_level : 0
  end

  def field_value_id
    field_value = field_value_obj
    field_value ? field_value.id : nil
  end

  def is_standard_document_field
    object.type == "StandardDocumentField" && object.created_by_user_id.present?
  end

  private
  def field_value_obj
    if scope[:document_id]
      @field_value_obj ||= DocumentFieldValue.where(:document_id => scope[:document_id], :local_standard_document_field_id => object.field_id).first
      @field_value_obj && @field_value_obj.document.accessible_by_me?(scope[:current_user]) ? @field_value_obj : nil
    else
      nil
    end
  end
end
