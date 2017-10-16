class Api::Web::V1::BaseDocumentSerializer < ActiveModel::Serializer
  def first_page_s3_key
    object.first_page_thumbnail if object.pages.any?
  end

  def pages_count
    object.pages.size
  end

  def document_owners_count
    object.document_owners.count
  end

  def first_document_owner_name
    if object.document_owners.any?
      first_owner = object.document_owners.first.owner
      first_owner.owner_name || first_owner.owner_email
    end
  end

  def symmetric_key
    symmetric_key = object.symmetric_keys.for_user_access(scope.id).first
    Api::Web::V1::SymmetricKeySerializer.new(symmetric_key, { :scope => scope, :root => false })
  end

  def have_access
    object.accessible_by_me?(scope) if object.standard_document_id
  end
end
