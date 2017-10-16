module Api::DocytBot::V1::Responses::DocumentFieldResponseModule
  include ::Api::DocytBot::V1::Responses::BaseResponseModule
  
  def generate_field_value_response
    if @field_ids.blank?
      return generate_plain_text_response("field_response.no_fields")
    else
      dml_arr = []
      @field_ids.each do |field_id, field_hashes|
        field_obj = StandardDocumentField.where(:id => field_id.to_i).first
        field_hashes.each do |field_hash|
          response_group_identifier = SecureRandom.uuid
          doc = Document.where(:id => field_hash[:doc_id]).first
          field_value = field_hash[:value]
          if field_value.blank?
            next 
          else
            first_name = get_first_names_string(doc.document_owners.map(&:owner))
            if !field_obj.encryption
              if field_obj.speech_text
                dml_arr << { :message => field_obj_response(field_obj, doc, first_name), :type => REGULAR_TEXT, response_group: response_group_identifier }
              else
                if first_name.blank?
                  dml_arr << { :message => "#{field_obj.name} in the document, #{doc.standard_document.name} is #{field_value}.", :type => REGULAR_TEXT, response_group: response_group_identifier }
                else
                  dml_arr << { :message => "#{field_obj.name} in #{first_name}'s #{doc.standard_document.name} is #{field_value}.", :type => REGULAR_TEXT, response_group: response_group_identifier }
                end
              end
            end
            response_hash = { :message => { :document => { :id => doc.id }}, :type => DOCUMENT_TEXT, response_group: response_group_identifier }
            DocytBotSessionDocument.create_response(@session, response_hash)
            dml_arr << response_hash
          end
        end
      end

      if dml_arr.blank?
        return generate_plain_text_response("field_response.no_fields")
      else
        return generate_dml_response(dml_arr)
      end
    end
  end

  private
  def field_obj_response(field_obj, doc, first_name)
    field_obj.compile_speech_text_for_contact(doc, @user, first_name) { |val, speech_type|
                                                    if @device_type == ALEXA
                                                      "<say-as interpret-as='#{speech_type}'>#{val}</say-as>"
                                                    else
                                                      val
                                                    end
                                                  }
  end
end
