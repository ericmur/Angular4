class SearchResultSerializer < ActiveModel::Serializer
  attributes :id, :name, :documents, :size, :folder_name, :standard_base_document_id

  delegate :current_user, to: :scope
  delegate :params, to: :scope

  def name
    object.standard_base_document.name
  end

  def document_type
    object.standard_base_document.type
  end

  def size
    object.standard_base_document.size
  end

  def folder_name
    object.standard_folder.name
  end

  # returning SearchDocumentSerializer instead of DocumentSerializer to reduce response output 
  def documents
    if object.standard_base_document.type == 'StandardDocument'
      user_id = params[:user_id] ? params[:user_id] : current_user.id
      documents = Document.where(:standard_document_id => object.standard_base_document_id, :consumer_id => user_id)
      if documents.first
        ActiveModel::ArraySerializer.new(documents, :each_serializer => SearchDocumentSerializer, :scope => scope)
      else
        []
      end
    else
      []
    end
  end
end
