class Api::Web::V1::DocumentFieldValuesController < Api::Web::V1::ApiController
  before_action :permitted_to_edit?, only: [:create, :update]

  def create
    form = ::Api::Web::V1::DocumentFieldValueCreateForm.from_params(document_field_value_params, user_id: current_advisor.id)

    if form.save
      render status: 200, json: form.get_document_field, serializer: ::Api::Web::V1::DocumentFieldValueSerializer
    else
      render status: 422, json: form.errors
    end
  end

  def update
    form = ::Api::Web::V1::DocumentFieldValueUpdateForm.from_params(document_field_value_params, user_id: current_advisor.id)

    if form.save
      render status: 200, json: form.to_model, serializer: ::Api::Web::V1::DocumentFieldValueSerializer
    else
      render status: 422, json: form.errors
    end
  end

  private

  def document_field_value_params
    params.require(:document_field_value).permit(
                                                  :id,
                                                  :input_value,
                                                  :local_standard_document_field_id,
                                                  :document_id,
                                                  :document_field_id
                                                )
  end

  def permitted_to_edit?
    document = Document.find(params['document_id'])
    render status: 422, json: {} unless document.uploader.id == current_advisor.id
  end

end
