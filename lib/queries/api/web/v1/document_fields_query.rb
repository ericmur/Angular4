class Api::Web::V1::DocumentFieldsQuery
  def initialize(current_advisor, params)
    @advisor      = current_advisor
    @document_id  = params[:document_id]
    @params       = params

    @documents              = Document.arel_table
    @document_fields        = DocumentField.arel_table
    @document_fields_values = DocumentFieldValue.arel_table
  end

  def get_document_fields
    return DocumentField.none unless @document_id
    return DocumentField.none unless Api::Web::V1::SymmetricKeyQuery.new(@advisor).get_documents.where(:id => @document_id).first

    standard_doc_fields = DocumentField.find_by_sql(
      get_standard_document_fields_sql
    )

    custom_doc_fields = DocumentField.find_by_sql(
      get_document_fields_sql
    )
    #Arel::Nodes::Union.new(standard_doc_fields.ast, custom_doc_fields.ast)
    #DocumentField.find_by_sql(standard_doc_fields.union(custom_doc_fields.to_sql))
    standard_doc_fields + custom_doc_fields
  end

  private

  #SQL parts
  def get_standard_document_fields_sql
    standard_documents = StandardDocument.arel_table

    @document_fields
      .join(standard_documents, Arel::Nodes::OuterJoin).on(standard_documents[:id].eq(@document_fields[:standard_document_id]))
      .join(@document_fields_values, Arel::Nodes::OuterJoin).on(
          @document_fields[:field_id].eq(@document_fields_values[:local_standard_document_field_id]).and(
            @document_fields_values[:document_id].eq(@document_id)
          )
        )
      .project(
        @document_fields[:id],
        @document_fields[:name],
        @document_fields[:data_type],
        @document_fields[:field_id],
        @document_fields_values[:value],
        @document_fields_values[:id].as("value_id"),
        @document_fields_values[:document_id]
      )
      .where(
        standard_documents[:id].eq(
          @documents.project(@documents[:standard_document_id])
            .where(@documents[:id].eq(@document_id))
            .take(1)
        )
      )
  end

  def get_document_fields_sql
    @document_fields
      .join(@documents, Arel::Nodes::OuterJoin).on(@documents[:id].eq(@document_fields[:document_id]))
      .join(@document_fields_values, Arel::Nodes::OuterJoin).on(@document_fields[:field_id].eq(@document_fields_values[:local_standard_document_field_id]))
      .project(
        @document_fields[:id],
        @document_fields[:name],
        @document_fields[:data_type],
        @document_fields_values[:value],
        @document_fields_values[:id].as("value_id"),
        @document_fields_values[:document_id],
        @document_fields[:field_id]
      )
      .where(
        @documents[:id].eq(@document_id)
      )
  end
end
