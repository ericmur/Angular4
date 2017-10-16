namespace :standard_document_fields do
  desc 'migrate document field'
  task migrate_types: :environment do
    BaseDocumentField.where(created_by_user_id: nil).update_all(type: 'StandardDocumentField')
    BaseDocumentField.where.not(created_by_user_id: nil).update_all(type: 'DocumentField')
  end
end
