class DocumentFieldValuesController < ApplicationController
  before_action :load_user_password_hash, :only => [:create, :update]
  before_action :load_document_field_value, :only => [:update, :destroy]
  before_action :verify_editing_perms_for_document, :only => [:create, :update, :destroy]
  after_action :notify_for_updated_field_value, only: [:create, :update, :destroy], if: -> { @document_field_value }
  after_action :add_value_as_suggestion, only: [:create, :update, :destroy], if: -> { @document_field_value }

  def create
    @document_field_value = DocumentFieldValue.new(document_field_value_params.merge(:user_id => self.current_user.id))

    respond_to do |format|
      if @document_field_value.save
        @document_field_value.process_notify_durations
        DocumentCacheService.update_cache([:document], @document_field_value.document.consumer_ids_for_owners)
        format.json { render :json => @document_field_value, serializer: DocumentFieldValueSerializer }
      else
        format.json { render :json => { :errors => @document_field_value.errors.full_messages }, :status => :not_acceptable }
      end
    end
  end

  def update
    respond_to do |format|
      if @document_field_value.update_attributes(document_field_value_params.merge(:user_id => self.current_user.id))
        @document_field_value.process_notify_durations
        DocumentCacheService.update_cache([:document], @document_field_value.document.consumer_ids_for_owners)

        format.json { render :json => @document_field_value, serializer: DocumentFieldValueSerializer }
      else
        format.json { render :json => { :errors => @document_field_value.errors.full_messages }, :status => :not_acceptable }
      end
    end
  end

  def destroy
    @document_field_value.destroy
    DocumentCacheService.update_cache([:document], @document_field_value.document.consumer_ids_for_owners)

    respond_to do |format|
      format.json { render json: { success: true } }
    end
  end

  private

  def notify_for_updated_field_value
    @document_field_value.document.enqueue_generate_notification_for_updated_value(current_user, @document_field_value.base_standard_document_field) if response.code == '200'
  end

  def add_value_as_suggestion
    @document_field_value.add_value_as_suggestion(current_user) if response.code == '200'
  end

  def document_field_value_params
    if params[:action] == 'create'
      params.require(:document_field_value).permit(:input_value, :document_id, :local_standard_document_field_id)
    else
      params.require(:document_field_value).permit(:input_value)
    end
  end

  def verify_editing_perms_for_document
    doc = nil
    if params[:action] == 'create'
      doc = Document.find(params[:document_field_value][:document_id])
    else
      doc = @document_field_value.document
    end

    unless doc.editable_by?(current_user)
      respond_to do |format|
        format.json { render :json => { :errors => ["Only owner of the document is allowed to make this change"]}, :status => :forbidden }
      end
    end
  end

  def load_document_field_value
    @document_field_value = DocumentFieldValue.where(:id => params[:id]).first
  end
end
