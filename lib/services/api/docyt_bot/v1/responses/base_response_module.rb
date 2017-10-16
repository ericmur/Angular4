require 'serializer_scope'

module Api::DocytBot::V1::Responses::BaseResponseModule
  ALEXA = "Alexa"
  DOCYT_BOT = "DocytBot"
  
  REGULAR_TEXT = "regular_message"
  DOCUMENT_TEXT = "document_message"
  HYPER_TEXT = "hyper_text"
  
  def generate_docs_response
    if @document_ids.blank?
      return generate_plain_text_response("document_response.no_documents")
    else
      response_group_identifier = SecureRandom.uuid
      dml_arr = []
      if @document_ids.count == 1 and @device_type != ALEXA
        doc = Document.where(:id => @document_ids.first).first
        if message = get_doc_message(doc)
          dml_arr << {  :message => message, :type => REGULAR_TEXT, response_group: response_group_identifier }
        end
      else
        if @document_ids.count > 3
          dml_arr << { :message => "<dml>I found #{@document_ids.count} documents matching your request. <docs token='#{response_group_identifier}'>View all</docs></dml>", :type => HYPER_TEXT, response_group: response_group_identifier }
        else
          
          dml_arr << { :message => "I found #{@document_ids.count} documents matching your request.", :type => REGULAR_TEXT, response_group: response_group_identifier }
        end
      end
      
      @document_ids.each_with_index do |document_id, index|
        doc = Document.where(:id => document_id).first
        if index < 3
          if @device_type == ALEXA
            if message = get_doc_message(doc)
              dml_arr << { :message => message, :type => REGULAR_TEXT, response_group: response_group_identifier }
            end
          else
            if message = get_doc_message(doc)
              response_hash = { :message => message, :type => REGULAR_TEXT, response_group: response_group_identifier }
              DocytBotSessionDocument.create_response(@session, response_hash)
              dml_arr << response_hash
            end
            
            response_hash = { :message => { :document => { :id => doc.id }}, :type => DOCUMENT_TEXT, response_group: response_group_identifier }
            DocytBotSessionDocument.create_response(@session, response_hash)
            dml_arr << response_hash

            response_hash = { :message => "\n", :type => REGULAR_TEXT, response_group: response_group_identifier }
            DocytBotSessionDocument.create_response(@session, response_hash)
            dml_arr << response_hash
          end
        else
          if message = get_doc_message(doc)
            response_hash = { :message => message, :type => REGULAR_TEXT, response_group: response_group_identifier }
            DocytBotSessionDocument.create_response(@session, response_hash)
          end
          
          response_hash = { :message => { :document => { :id => doc.id }}, :type => DOCUMENT_TEXT, response_group: response_group_identifier }
          DocytBotSessionDocument.create_response(@session, response_hash)

          response_hash = { :message => "\n", :type => REGULAR_TEXT, response_group: response_group_identifier }
          DocytBotSessionDocument.create_response(@session, response_hash)
        end
      end
      
      return generate_dml_response(dml_arr)
    end
  end
  
  private
  # "Sugam, Shilpa and Neha"
  def get_first_names_string(contacts)
    strs = []
    contacts.each do |contact|
      first_name = contact.first_name
      strs << first_name unless first_name.blank?
    end
    if strs.length > 1
      strs.slice(0..-2).join(", ") + " and " + strs.last
    elsif strs.length == 1
      strs.first
    else
      ""
    end
  end

  def generate_plain_text_response(en_tag)
    if @device_type == ALEXA
      return { "speech_output" => { "type" => "PlainText", "speech" => get_alexa_text(en_tag) } }
    else
      return [ { :type => REGULAR_TEXT, :message => get_app_text(en_tag) } ]
    end
  end

  def generate_dml_response(dml_arr)
    if @device_type == ALEXA
      dml_arr_filtered = dml_arr.select { |dml| dml[:type] == REGULAR_TEXT }
      return { "speech_output" => { "type" => "SSML", "speech" => dml_arr_filtered.join(" ") } }
    else
      scope = SerializerScope.new
      scope.current_user = @user
      scope.params = {}

      return dml_arr.map do |r|
        if r[:type] == DOCUMENT_TEXT
          document_id = r[:message][:document][:id]
          r[:message][:document] = ::Api::Mobile::V2::ComprehensiveDocumentSerializer.new(Document.find(document_id), { scope: scope, root: false })
        end
        r
      end
    end
  end

  def get_alexa_text(en_tag)
     I18n.t(en_tag + ".alexa")
  end

  def get_app_text(en_tag)
    I18n.t(en_tag + ".app")
  end
end
