module Api::DocytBot::V1::Responses::ExpiringDocumentListResponseModule
  include ::Api::DocytBot::V1::Responses::BaseResponseModule

  def generate_expiring_docs_response
    generate_docs_response
  end

  def get_doc_message(doc)
    first_name = get_first_names_string(doc.document_owners.map(&:owner))
    field = doc.standard_document.standard_document_fields.where("data_type = 'expiry_date'").select(:id, :field_id).first
    expiry_value_obj = doc.document_field_values.where(:local_standard_document_field_id => field.field_id).first
    return nil if expiry_value_obj.nil?
    expiry_value_obj.user_id = @user.id
    val = expiry_value_obj.field_value
    message = ""
    if doc.standard_document.primary_name
      doc_name = doc.compile_primary_name(@user) { |val, speech_type|
        if @device_type == ALEXA
          "<say-as interpret-as='#{speech_type}'>#{val}</say-as>"
        else
          val
        end
      }
    else
      doc_name = doc.standard_document.name
    end
    val_date = Date.strptime(val, "%m/%d/%Y")
    val_display_str = val_date.strftime("%B %d, %Y")
    if val_date > Time.now
      message = "#{first_name}'s #{doc_name} is expiring on #{val_display_str}"
    else
      message = "#{first_name}'s #{doc_name} expired on #{val_display_str}"
    end
    message
  end
end
