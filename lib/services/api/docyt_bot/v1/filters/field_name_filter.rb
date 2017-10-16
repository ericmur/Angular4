class Api::DocytBot::V1::Filters::FieldNameFilter < Api::DocytBot::V1::Filters::BaseFilter
  def initialize(user, ctx)
    @user = user
    @ctx = ctx
    @intent = ctx[:intent]
    @pre_filter_docs_ids = ctx[:document_ids]
  end

  def call
    unless @intent == ::Api::DocytBot::V1::IntentsService::GET_DOC_FIELD_INFO
      return @ctx
    end
    field_ids = { }
    all_fields = get_fields
    all_fields.each do |field_id, field_hsh|
      field_aliases = field_hsh[:aliases]
      if field_aliases.find { |field_alias| ::Api::DocytBot::V1::Matcher.new(@ctx[:text]).inclusion_score_for(field_alias) > ::Api::DocytBot::V1::Matcher::DOC_FIELD_THRESHOLD_SCORE }
        field_ids[field_id.to_s] = field_hsh[:values]
      end
    end
    
    @ctx[:field_ids] = field_ids
    unless (docs_ids = get_filtered_documents_ids_by_field_ids(field_ids.keys)).blank?
      @ctx[:document_ids] = get_filtered_documents_ids_by_field_ids(field_ids.keys)
    end
    
    return @ctx
    
  end

  private
  def get_filtered_documents_ids_by_field_ids(field_ids)
    Document.where(:id => @pre_filter_docs_ids).where(:standard_document_id => StandardDocumentField.where(:id => field_ids).pluck(:standard_document_id)).pluck(:id)
  end
  
  def get_fields
    hsh = { }
    @pre_filter_docs_ids.each do |doc_id|
      doc = Document.find(doc_id)
      next if doc.standard_document.nil?
      fields = doc.standard_document.standard_document_fields.select(:id, :name, :field_id)
      fields.each do |field|
        hsh[field.id.to_s] ||= { }
        hsh[field.id.to_s][:aliases] = [field.name] + field.aliases.pluck(:name)
        hsh[field.id.to_s][:values] ||= []
        
        field_val_obj = doc.document_field_values.where(:local_standard_document_field_id => field.field_id).first
        next if field_val_obj.nil? or !field_val_obj.document.accessible_by_me?(@user)
        field_val_obj.user_id = @user.id
        hsh[field.id.to_s][:values] << { :doc_id => doc_id, :value => field_val_obj.field_value }
      end
    end
    hsh
  end
end
