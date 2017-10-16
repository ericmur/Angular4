namespace :documents do
  desc "Resend push notification for existing DocumentAccessRequest"
  task resend_document_access_request_notification: :environment do
    DocumentAccessRequest.all.group_by {|d| [d.uploader_id, d.created_by_user_id] }.each do |_, access_requests|
      access_request = access_requests.first
      access_request.send_request_notification if access_request
    end
  end

  desc "Rebuild standard base document permissions"
  task rebuild_standard_base_document_permissions: :environment do
    Permission.destroy_all
    Document.find_each do |document|
      document.generate_standard_base_document_permissions
    end
  end

  desc "Rebuild permissions"
  task rebuild_permissions: :environment do
    DocumentPermission.destroy_all
    Document.find_each do |document|

      document.transaction do
        begin
          document.document_permissions.destroy_all

          owner_permissions = document.document_owners.map do |document_owner|
            if document_owner.connected?
              [document_owner.owner, DocumentPermission::OWNER]
            else
              permission_owner = nil
              permission_owner_class = document_owner.owner.class.name
              if permission_owner_class == 'GroupUser'
                permission_owner = document_owner.owner.group.owner
              elsif permission_owner_class == 'Client'
                if document_owner.owner.connected?
                  permission_owner = document_owner.owner.consumer
                else
                  permission_owner = document_owner.owner.advisor
                end
              else
                raise 'Invalid case. #{permission_owner_class} is not registered as owner_type'
              end
              if permission_owner
                [permission_owner, DocumentPermission::CUSTODIAN]
              else
                nil # nil since there's no permission candidate from document owners
              end
            end
          end

          owner_permissions.reject!(&:nil?)

          sharee_permissions = document.sharees_for_documents.map do |sharee|
            [sharee, DocumentPermission::SHAREE]
          end

          uploader_permissions = [document.uploader, DocumentPermission::UPLOADER]

          eligible_users_and_permissions = [owner_permissions.flatten, sharee_permissions.flatten, uploader_permissions]
          eligible_users_and_permissions.reject!(&:blank?)
          eligible_users_and_permissions.each do |user, v|
            DocumentPermission.create_permissions_if_needed(document, user, v)
          end

        rescue => e
          puts "#{e.message}"
          raise ActiveRecord::Rollback
        end
      end

    end
  end
end
