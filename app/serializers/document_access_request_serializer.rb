class DocumentAccessRequestSerializer < ActiveModel::Serializer
  attributes :id, :requester_id, :uploader_name, :description, :requester_name

  def requester_id
    object.created_by_user_id
  end

  def requester_name
    object.created_by_user.first_name
  end

  def uploader_name
    object.uploader.first_name
  end

  def description
    standard_document = object.document.standard_document
    standard_folder = standard_document.standard_folder_standard_documents.first.standard_folder

    [requester_name, standard_folder.name, standard_document.name].join(' / ')
  end
end