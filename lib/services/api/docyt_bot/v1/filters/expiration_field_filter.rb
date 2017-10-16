class Api::DocytBot::V1::Filters::ExpirationFieldFilter < Api::DocytBot::V1::Filters::BaseFilter
  def initialize(user, ctx)
    @user = user
    @ctx = ctx
    @intent = ctx[:intent]
    @pre_filter_docs_ids = ctx[:document_ids]
  end

  def call
    unless @intent == ::Api::DocytBot::V1::IntentsService::GET_DOC_EXPIRATION_INFO
      return @ctx
    end

    @ctx[:field_ids] = get_expiration_fields
    
    return @ctx
  end

  private
  
  def get_expiration_fields
    hsh = { }
    @pre_filter_docs_ids.each do |doc_id|
      doc = Document.find(doc_id)
      fields = doc.standard_document.standard_document_fields.where("data_type = 'expiry_date'").select(:id, :field_id)
      fields.each do |field|
        hsh[field.id.to_s] ||= []
        
        field_val_obj = doc.document_field_values.where(:local_standard_document_field_id => field.field_id).first
        next if field_val_obj.nil? or !field_val_obj.document.accessible_by_me?(@user)
        field_val_obj.user_id = @user.id
        hsh[field.id.to_s] << { :doc_id => doc_id, :value => field_val_obj.field_value }
      end
    end
    hsh
  end
end
