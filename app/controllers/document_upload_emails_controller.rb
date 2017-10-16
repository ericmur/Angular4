class DocumentUploadEmailsController < ApplicationController
  respond_to :json
  before_action :load_standard_document
  before_action :load_business

  def create
    upload_email = DocumentUploadEmailBuilder.new(current_user, params[:email], @standard_document, @business).create_and_deliver

    if upload_email.persisted? && upload_email.errors.empty?
      render status: 200, json: upload_email
    else
      render status: 422, json: { errors: upload_email.errors.full_messages }
    end
  end

  private

    def load_standard_document
      @standard_document = StandardDocument.find(params[:standard_document_id])
    end

    def load_business
      @business = Business.find(params[:business_id]) if params[:business_id].present?
    end
end