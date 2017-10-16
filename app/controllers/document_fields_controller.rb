class DocumentFieldsController < ApplicationController
  before_action :load_user_password_hash, :only => [:create]
  before_action :load_document_field, :only => [:destroy]

  def create
    params[:document_field].reject!{|k, _| k.to_s == "type" }
    params[:document_field].reject!{|k, _| k.to_s == "notify" }
    @document_field = self.current_user.document_fields_by_me.build(document_field_params)
    if @document_field.data_type == "expiry_date"
      @document_field.notify = true
      NotifyDuration::DEFAULT_EXPIRY_NOTIFY_DURATIONS.each do |n|
        @document_field.notify_durations.build(amount: n[:amount], unit: n[:unit])
      end
    elsif @document_field.data_type == "due_date"
      @document_field.notify = true
      NotifyDuration::DEFAULT_DUE_NOTIFY_DURATIONS.each do |n|
        @document_field.notify_durations.build(amount: n[:amount], unit: n[:unit])
      end
    end

    if @document_field.save
      @document_field.reload #to get the new auto-incremented field_id value from DB
      @document_field.document.enqueue_generate_notification_for_new_field(current_user, @document_field)

      DocumentCacheService.update_cache([:document], @document_field.document.consumer_ids_for_owners)

      respond_to do |format|
        #We need to pass in scope the way it is passed here, since StandardDocumentFieldSerializer is invoked from other serializers (app/serializers/concerns/serializer_standard_fields.rb).
        #These other serializers have to pass in document_id along with current_user and in order to pass in 2 parameters passing scope like this is the only way in the current version of ActiveModel Serializer
        format.json { render :json => @document_field, :serializer => BaseDocumentFieldSerializer, :scope => { :current_user => current_user }, :root => 'document_field', :status => :ok }
      end
    else
      respond_to do |format|
        format.json { render :json => { :errors => @document_field.errors.full_messages }, :status => :not_acceptable }
      end
    end
  end

  def destroy
    @document = @document_field.document
    consumer_ids_for_owners = @document.consumer_ids_for_owners

    @document.enqueue_generate_notification_for_deleted_field(current_user, @document_field)

    DocumentCacheService.update_cache([:document], consumer_ids_for_owners)

    @document_field.destroy
    respond_to do |format|
      format.json { render :nothing => true }
    end
  end

  private

  def load_document_field
    is_editable_by_user = false
    @document_field = DocumentField.where(field_id: params[:id]).first
    if @document_field
      @document = @document_field.document
      if @document && @document.editable_by?(current_user) && @document_field.created_by_user_id.present?
        is_editable_by_user = true
      end
    end

    unless is_editable_by_user
      respond_to do |format|
        format.json { render status: :not_found, json: { errors: [I18n.t('errors.document_field.field_not_found')] } }
      end
    end
  end

  def document_field_params
    params.require(:document_field).permit(:document_id, :name,
                                           :data_type, :type, :notify, :encryption)
  end
end
