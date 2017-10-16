namespace :business do
  desc 'Create new business for user'
  task :create_business, [:user_id, :name, :standard_category_id, :entity_type, :street, :city, :state, :zip] => :environment do |t, args|
    user_id = args[:user_id]
    name = args[:name]
    standard_category = StandardCategory.find(args[:standard_category_id])
    entity_type = args[:entity_type]
    address_street = args[:street]
    address_city = args[:city]
    address_state = args[:state]
    address_zip = args[:zip]

    user = User.find(user_id)
    business = Business.new
    business.name                 = name
    business.entity_type          = entity_type
    business.address_street       = address_street
    business.address_city         = address_city
    business.address_state        = address_state
    business.address_zip          = address_zip
    business.standard_category_id = standard_category.id
    business.business_partners.build(user: user)
    business.save!
    business.generate_folder_settings!
    business.generate_notifications_for_new_business!(user)
    business.migrate_partners_account_type_to_business!(user)

    user = User.find(user_id)
    if user.consumer_account_type_id != ConsumerAccountType::BUSINESS
      user.consumer_account_type_id = ConsumerAccountType::BUSINESS
      user.save!
    end

    UserFolderSetting.setup_folder_setting_for_user(user)
    DocumentCacheService.update_cache([:folder_setting], business.business_partners.pluck(:user_id))
  end

  desc "Add Business partner to Business"
  task :add_business_partner, [:business_name, :user_email] => :environment do |t, args|
    b = Business.find_by_name(args[:business_name])
    u = User.find_by_email(args[:user_email])
    b.business_partners.create!(:user_id => u.id)
    b.generate_folder_settings!
    
    u.consumer_account_type_id = ConsumerAccountType.business_type.first.id
    if u.save!
      UserFolderSetting.setup_folder_setting_for_user(u)
      DocumentCacheService.update_cache([:folder_setting], [u.id])
    end
  end

  desc "One time migration to migrate a business document into business structure"
  task :migrate_business_document, [:doc_ids, :business_name] => :environment do |t, args|
    args[:doc_ids].split.each do |doc_id|
      doc = Document.find(doc_id)
      doc_owner = doc.document_owners.find { |doc_owner|
        if doc_owner.owner_type == 'User'
          biz_partner = doc_owner.owner.business_partnerships.first
          biz_partner ? biz_partner.business : nil
        else
          nil
        end
      }
      next if doc_owner.nil?
      business = Business.where(:name => args[:business_name]).first
      
      if doc.standard_document.consumer_id and doc.standard_document.owners.where(:owner_type => 'Business').first.nil?
        if business
          doc.standard_document.standard_base_document_account_types.create!(:consumer_account_type_id => ConsumerAccountType::BUSINESS, :show => true)
          doc.standard_document.owners.create!(:owner_id => business.id, :owner_type => 'Business')
        end
      end
      
      if doc.business_documents.empty?
        if business
          if doc.symmetric_keys.for_user_access(doc_owner.owner_id).exists?
            doc.business_documents.create!(:business_id => business.id)
            doc.business_documents.each do |business_document|
              business_document.business.business_partners.each do |business_partner|
                DocumentPermission.create_permissions_if_needed(doc, business_partner.user, DocumentPermission::BUSINESS_PARTNER)
              end
            end
            doc.generate_standard_base_document_permissions
          else
            raise "BusinessPartner does not have access to document. Document: #{doc.id}"
          end
        else
          puts "No Business found for DocumentID: #{doc.id} of type: #{doc.standard_document.name}. Delete these or create a business for this document's owner"
        end
      end
    end
  end

  desc "One time (only the first time) migration to migrate business documents into business structure"
  task migrate_business_documents: :environment do
    business_standard_folders = StandardBaseDocumentAccountType.for_consumer_account_type(ConsumerAccountType::BUSINESS).map(&:standard_base_document).select { |sbd|
      sbd.type == 'StandardFolder'
    }

    business_standard_documents_ids = StandardFolderStandardDocument.where(:standard_folder_id => business_standard_folders.map(&:id)).map { |sfsd| sfsd.standard_base_document_id }

    Document.where(:standard_document_id => business_standard_documents_ids).each do |doc|
      doc_owner = doc.document_owners.find { |doc_owner|
        if doc_owner.owner_type == 'User'
          biz_partner = doc_owner.owner.business_partnerships.first
          biz_partner ? biz_partner.business : nil
        else
          nil
        end
      }
      next if doc.business_documents.first

      business = nil
      if doc_owner
        bs = doc_owner.owner.business_partnerships
        if bs.count > 1
          puts "Found more than 1 business for, user: #{doc_owner.owner.email}, document: #{doc.id}, #{doc.standard_document.name}, #{doc.document_field_values.map(&:value)}. Skipping..."
          next
        end
        business = bs.first.business
      end

      if doc.standard_document.consumer_id and doc.standard_document.owners.where(:owner_type => 'Business').first.nil?
        if business
          doc.standard_document.standard_base_document_account_types.create!(:consumer_account_type_id => ConsumerAccountType::BUSINESS, :show => true)
          doc.standard_document.owners.create!(:owner_id => business.id, :owner_type => 'Business')
        end
      end
      
      if doc.business_documents.empty?
        if business
          if doc.symmetric_keys.for_user_access(doc_owner.owner_id).exists?
            doc.business_documents.create!(:business_id => business.id)
            doc.business_documents.each do |business_document|
              business_document.business.business_partners.each do |business_partner|
                DocumentPermission.create_permissions_if_needed(doc, business_partner.user, DocumentPermission::BUSINESS_PARTNER)
              end
            end
            doc.generate_standard_base_document_permissions
          else
            raise "BusinessPartner does not have access to document. Document: #{doc.id}"
          end
        else
          puts "No Business found for DocumentID: #{doc.id} of type: #{doc.standard_document.name}. Delete these or create a business for this document's owner"
        end
      end
    end
  end

  desc 'Add Business to Client/GroupUser (Employee/Contractor)'
  task migrate_client_and_group_user: :environment do
    User.find_each do |user|
      businesses = Business.for_user(user)
      businesses_count = businesses.count

      clients_count = user.clients_as_advisor.count
      group_users_count = user.group_users_as_group_owner.where(label: [GroupUser::EMPLOYEE, GroupUser::CONTRACTOR]).where(:business_id => nil).count

      if businesses_count == 0
        if clients_count > 0 || group_users_count > 0
          puts "User: #{user.id} has Client: #{clients_count} and GroupUser: #{group_users_count}. But do not have registered business."
          next
        end
      elsif businesses_count > 1
        if clients_count > 0 || group_users_count > 0
          puts "User: #{user.id} has more than one business registered. Client: #{clients_count} and GroupUser: #{group_users_count}."
          next
        end
      end

      first_business = businesses.first

      user.group_users_as_group_owner.find_each do |group_user|
        if group_user.business.blank? && group_user.require_business?
          group_user.business = first_business
          group_user.save
        end
      end

      user.clients_as_advisor.find_each do |client|
        client.business = first_business
        client.save
      end

    end
  end

  desc 'Migrate Business Information to Business'
  task migrate_business_information: :environment do
    BusinessInformation.find_each do |business_information|
      business_information.migrate_to_business
    end
  end
end
