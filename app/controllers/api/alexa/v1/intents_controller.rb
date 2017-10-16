class Api::Alexa::V1::IntentsController < Api::Alexa::V1::ApiController
  before_filter :set_docyt_bot_session

  def get_field_value
    response = ::Api::DocytBot::V1::IntentsService.new(self.current_user, @docyt_bot_session, field_value_params).get_response
    render :json => response.to_json
  end

  def get_expiring_docs
    response = ::Api::DocytBot::V1::IntentsService.new(self.current_user, @docyt_bot_session, expiring_docs_params).get_response
    render :json => response.to_json
  end

  def get_due_docs
    
  end
  
  private
  def set_docyt_bot_session
    @docyt_bot_session = DocytBotSession.find_by_session_token(params[:session_token])
  end
  
  def field_value_params
    params.permit(:slots, :device_type).merge({ :intent => ::Api::DocytBot::V1::IntentsService::GET_DOC_FIELD_INFO })
    #(:field_name, :relationship_type, :contact_name, :descriptor)
  end

  def expiring_docs_params
    params.permit(:slots, :device_type).merge({ :intent => ::Api::DocytBot::V1::IntentsService::GET_EXPIRING_DOCS_LIST })
    #(:from_date, :to_date, :expiring_date, :relationship_type, :contact_name, :descriptor, :document_type)
  end
end
