require 'slack_helper'
class Api::DocytBot::V1::Responses::Response
  include ::Api::DocytBot::V1::Responses::DocumentFieldResponseModule
  include ::Api::DocytBot::V1::Responses::DocumentListResponseModule
  include ::Api::DocytBot::V1::Responses::ExpiringDocumentListResponseModule
  include ::Api::DocytBot::V1::Responses::DueDocumentListResponseModule
  include ::Api::DocytBot::V1::Responses::TotalAmountResponseModule
  def initialize(user, session, ctx, device_type)
    @user = user
    @session = session
    @device_type = device_type
    if ctx
      @intent = ctx[:intent]
      @field_ids = ctx[:field_ids]
      @document_ids = ctx[:document_ids]
      @total = ctx[:total]
    else
      @intent = nil
    end
  end

  def generate
    case @intent
    when ::Api::DocytBot::V1::IntentsService::GET_DOC_FIELD_INFO
      generate_field_value_response
    when ::Api::DocytBot::V1::IntentsService::GET_DOCS_LIST
      generate_docs_response
    when ::Api::DocytBot::V1::IntentsService::GET_EXPIRING_DOCS_LIST
      generate_expiring_docs_response
    when ::Api::DocytBot::V1::IntentsService::GET_DUE_DOCS_LIST
      generate_due_docs_response
    when ::Api::DocytBot::V1::IntentsService::GET_PAST_DUE_DOCS_LIST
      generate_due_docs_response
    when ::Api::DocytBot::V1::IntentsService::GET_DOC_EXPIRATION_INFO
      generate_expiring_docs_response
    when ::Api::DocytBot::V1::IntentsService::GET_EXPIRED_DOCS_LIST
      generate_expiring_docs_response
    when ::Api::DocytBot::V1::IntentsService::GET_TOTAL_AMOUNT
      generate_total_amount_response
    else
      SlackHelper.ping({ channel: "#errors", username: "DocytBot", message: "Invalid intent: #{@intent}, when creating response"})
      generate_plain_text_response('could_not_understand')
    end
  end

end
