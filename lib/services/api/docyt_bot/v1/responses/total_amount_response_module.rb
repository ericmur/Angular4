module Api::DocytBot::V1::Responses::TotalAmountResponseModule
  include ::Api::DocytBot::V1::Responses::BaseResponseModule
  
  def generate_total_amount_response
    if @document_ids.blank?
      return generate_plain_text_response("total_response.no_documents")
    else
      dml_arr = []
      response_group_identifier = SecureRandom.uuid
      dml_arr << { :message => "The total is $#{'%.2f' % @total}.", :type => REGULAR_TEXT, response_group: response_group_identifier }
      dml_arr << { :message => "Here is a list of documents that matched your request:", :type => REGULAR_TEXT, response_group: response_group_identifier }
      @document_ids.each do |doc_id|
        response_hash = { :message => { :document => { :id => doc_id}}, :type => DOCUMENT_TEXT, response_group: response_group_identifier }
        DocytBotSessionDocument.create_response(@session, response_hash)
        dml_arr << response_hash
      end

      return generate_dml_response(dml_arr)
    end
  end

  
end
