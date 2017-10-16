class Api::DocytBot::V1::Filters::CurrencyComputeFilter < Api::DocytBot::V1::Filters::BaseFilter
  def initialize(user, ctx)
    @user = user
    @ctx = ctx
    @intent = ctx[:intent]
    @pre_filter_docs_ids = ctx[:document_ids]
  end

  def call
    docs = Document.where(:id => @pre_filter_docs_ids)

    tot = 0
    docs.each do |doc|
      std_field = doc.standard_document.standard_document_fields.where(:data_type => 'currency').first
      if std_field.nil?
        next
      end
      field_value_obj = doc.document_field_values.where(:local_standard_document_field_id => std_field.field_id).first
      if field_value_obj
        field_value_obj.user_id = @user.id
        tot += field_value_obj.value ? field_value_obj.value.to_f : 0
      end
    end

    @ctx[:total] = tot
    @ctx
  end
end
