class Api::Mobile::V2::DocytBotSessionsController < Api::Mobile::V2::ApiController
  before_action :load_user_password_hash, only: [:index, :view_all]
  before_action :set_docyt_bot_session, except: [:samples]

  def index
    response = ::Api::DocytBot::V1::IntentsService.new(self.current_user, @docyt_bot_session, intent_params).get_response

    render json: { response: response, session_token: @docyt_bot_session.session_token }.to_json
  end

  def view_all
    session_documents = @docyt_bot_session.docyt_bot_session_documents.where(response_group: params[:response_group])
    response = session_documents.map { |sd| sd.serialize_response_for(current_user, params) }

    render json: { response: response, session_token: @docyt_bot_session.session_token }.to_json
  end

  def samples
    render json: { response: Intent::SAMPLE_UTTERANCES }.to_json
  end

  def destroy
    @docyt_bot_session.destroy if @docytbot_session

    render nothing: true, status: :ok
  end
  
  private

  def set_docyt_bot_session
    if params[:session_token].blank?
      @docyt_bot_session = DocytBotSession.create_with_token!
    else
      @docyt_bot_session = DocytBotSession.find_by_session_token(params[:session_token])
    end
  end
  
  def intent_params
    params.permit(:text, :device_type, :session_token)
  end
end
