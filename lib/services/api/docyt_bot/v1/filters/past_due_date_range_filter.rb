class Api::DocytBot::V1::Filters::PastDueDateRangeFilter < Api::DocytBot::V1::Filters::BaseFilter
  def initialize(user, ctx)
    @user = user
    
    @ctx = ctx
    @pre_filter_docs_ids = ctx[:document_ids]
    @intent = ctx[:intent]
  end

  def call
    return @ctx unless @intent == ::Api::DocytBot::V1::IntentsService::GET_PAST_DUE_DOCS_LIST
    
    @ctx[:document_ids] = get_past_due_docs_ids
    return @ctx
  end

  private
  def get_past_due_docs_ids
    arr = []
    
    @pre_filter_docs_ids.each do |doc_id|
      doc = Document.find(doc_id)
      fields = doc.standard_document.standard_document_fields.where("data_type = ?", 'due_date').select(:field_id)
      fields.each do |field|
        field_val_obj = doc.document_field_values.where(:local_standard_document_field_id => field.field_id).first
        if field_val_obj.nil? or !field_val_obj.document.accessible_by_me?(@user)
          next
        end
        
        field_val_obj.user_id = @user.id
        field_val_dt = field_val_obj.date_value
        if field_val_dt > Time.now
          next
        end
        arr << doc_id
      end
    end
    arr
  end

end
