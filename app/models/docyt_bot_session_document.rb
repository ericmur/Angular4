class DocytBotSessionDocument < ActiveRecord::Base
  belongs_to :document
  belongs_to :docyt_bot_session

  def self.create_response(session, response_hash)
    return unless response_hash[:type] == ::Api::DocytBot::V1::Responses::BaseResponseModule::DOCUMENT_TEXT
    return unless response_hash[:message].is_a?(Hash)

    document_id = response_hash[:message][:document][:id]
    response_group  = response_hash[:response_group]

    DocytBotSessionDocument.create(docyt_bot_session_id: session.id, document_id: document_id, response_group: response_group)
  end

  def serialize_response_for(user, params)
    response_type = ::Api::DocytBot::V1::Responses::BaseResponseModule::DOCUMENT_TEXT
    scope = SerializerScope.new
    scope.current_user = user
    scope.params = params

    document_serializer = ::Api::Mobile::V2::ComprehensiveDocumentSerializer.new(document, { scope: scope, root: false })

    { message: { document: document_serializer }, type: response_type, response_group: response_group }
  end
end
