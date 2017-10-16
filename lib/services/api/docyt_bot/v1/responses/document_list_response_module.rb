module Api::DocytBot::V1::Responses::DocumentListResponseModule
  include ::Api::DocytBot::V1::Responses::BaseResponseModule
  MAX_DOCS_COUNT = 25
  MAX_DOCS_COUNT_ALEXA = 5

  def get_max_docs_count
    @device_type == ALEXA ? MAX_DOCS_COUNT_ALEXA : MAX_DOCS_COUNT
  end

  def generate_docs_response
    if @document_ids.blank?
      return generate_plain_text_response("document_response.no_documents")
    else
      response_group_identifier = SecureRandom.uuid
      dml_arr = []
      if @document_ids.count == 1 and @device_type != ALEXA
        doc = Document.where(:id => @document_ids.first).first
        first_name = get_first_names_string(doc.document_owners.map(&:owner))
        if first_name.blank?
          dml_arr << {  :message => "Here is the document you requested", :type => REGULAR_TEXT, response_group: response_group_identifier }
        else
          dml_arr << {  :message => "Here is #{first_name}'s #{doc.standard_document.name}", :type => REGULAR_TEXT, response_group: response_group_identifier }
        end
      else
        if @document_ids.count > 3

          if @document_ids.count > get_max_docs_count
            dml_arr << { :message => "Too many documents matched your request. Below are the top #{MAX_DOCS_COUNT}.", :type => REGULAR_TEXT, response_group: response_group_identifier }
          else
            dml_arr << { :message => "<dml>I found #{@document_ids.count} documents matching your request. Below are the top 3. <docs token='#{response_group_identifier}'>View all</docs></dml>", :type => HYPER_TEXT, response_group: response_group_identifier }
          end
        else
          dml_arr << { :message => "I found #{@document_ids.count} documents matching your request.", :type => REGULAR_TEXT, response_group: response_group_identifier }
        end
      end

      docs_ids = []
      if @document_ids.count > get_max_docs_count
        docs_ids = @document_ids.slice(0..get_max_docs_count)
      else
        docs_ids = @document_ids
      end

      docs_ids.each_with_index do |document_id, index|
        doc = Document.where(:id => document_id).first
        if index < 3 or @document_ids.count > get_max_docs_count
          if @device_type == ALEXA
            first_name = get_first_names_string(doc.document_owners.map(&:owner))
            doc_name = doc.standard_document.primary_name ? doc.standard_document.primary_name : doc.standard_document.name
            dml_arr << { :message => "#{first_name}'s #{doc_name}", :type => REGULAR_TEXT }
          else
            response_hash = { :message => { :document => { :id => doc.id }}, :type => DOCUMENT_TEXT, response_group: response_group_identifier }
            DocytBotSessionDocument.create_response(@session, response_hash)
            dml_arr << response_hash
          end
        else
          response_hash = { :message => { :document => { :id => doc.id }}, :type => DOCUMENT_TEXT, response_group: response_group_identifier }
          DocytBotSessionDocument.create_response(@session, response_hash)
        end
      end

      return generate_dml_response(dml_arr)
    end
  end
end
