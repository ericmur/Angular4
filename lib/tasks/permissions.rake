namespace :permissions do  
  desc "Rebuild system standard base document permissions"
  task rebuild_system_permissions: :environment do
    Permission.joins(:standard_base_document).where(standard_base_documents: { consumer_id: nil }).destroy_all
    standard_base_documents_ids = StandardBaseDocumentAccountType.only_system_for_consumer_account_type(ConsumerAccountType::INDIVIDUAL).pluck(:standard_folder_id)
    User.find_each do |user|
      Permission.setup_system_documents_permissions_for(user, standard_base_documents_ids)
    end

    standard_base_documents_ids = StandardBaseDocumentAccountType.only_system_for_consumer_account_type(ConsumerAccountType::BUSINESS).pluck(:standard_folder_id)
    Business.find_each do |business|
      Permission.setup_system_business_documents_permissions_for(business, standard_base_documents_ids)
    end
  end

  desc "Rebuild custom standard base document permissions"
  task rebuild_custom_permissions: :environment do
    Permission.joins(:standard_base_document).where.not(standard_base_documents: { consumer_id: nil }).destroy_all

    Document.find_each do |document|
      document.generate_standard_base_document_permissions
    end
  end
end