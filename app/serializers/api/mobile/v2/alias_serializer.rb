class Api::Mobile::V2::AliasSerializer < ActiveModel::Serializer
  attributes :id, :name, :aliasable_id, :aliasable_type, :standard_document_id, :field_id

  # field_id will be used to compare searched alias with existing standard_document_fields on client side.
  def field_id
    if object.aliasable_type == "BaseDocumentField"
      object.aliasable.field_id
    end
  end

  # helper attribute to help associate alias with standard_document on client side.
  def standard_document_id
    case object.aliasable_type
    when "BaseDocumentField"
      return object.aliasable.standard_document_id
    when "StandardBaseDocument"
      return object.aliasable.id
    end
  end
end
