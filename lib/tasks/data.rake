namespace :data do
  desc "Generate referral codes"
  task generate_referral_codes: :environment do
    ReferralCode.delete_all
    User.find_each do |user|
      attempts = 0
      begin
        referral_code = user.build_referral_code
        referral_code.code = SecureRandom.hex(3).downcase
        referral_code.save!
      rescue ActiveRecord::RecordNotUnique => e
        attempts = attempts.to_i + 1
        retry if attempts < 10
        raise e, "Retries exhausted"
      end
    end
  end


  desc "Cleanup invalid invitations"
  task cleanup_invalid_invitations: :environment do
    GroupUser.find_each do |group_user|
      invitation = group_user.invitation
      if invitation && invitation.pending? && group_user.user.present?
        invitation.destroy
      end
    end
  end

  desc "Fix standard folder rank"
  task fix_standard_folder_rank: :environment do
    system_folder_rank = StandardFolder::BUFFET_FOR_FUTURE_SYSTEM_FOLDER_RANK
    StandardFolder.where.not(consumer_id: nil).find_each do |standard_folder|
      if standard_folder.rank <= system_folder_rank
        standard_folder.rank = nil
        standard_folder.send('set_rank')
        standard_folder.save!
      end
    end
  end

  desc "Update new invitee_type field"
  task set_invitation_invitee_type: :environment do
    Invitationable::Invitation.update_all(invitee_type: 'Consumer')
  end

  desc "Migrate exising inviation type"
  task migrate_existing_invitations_type: :environment do
    Invitationable::Invitation.find_each.each do |invitation|
      invitation.update_column(:type, "Invitationable::ConsumerToConsumerInvitation") if invitation.type.blank?
    end
  end

  desc "Update document's initial pages completion status"
  task :update_document_initial_pages_completion => :environment do
    Document.find_each do |document|
      document.update_initial_pages_completion
    end
  end

  desc "Migrate missing StandardBaseDocumentOwner"
  task migrate_standard_base_document_owners: :environment do
    DocumentOwner.find_each.each do |document_ownership|
      document_ownership.generate_standard_base_document_owner
    end
    nil
  end

  desc "Move StandardDocument with missing StandardFolder to Miscellaneous"
  task migrate_missing_folder: :environment do
    misc = StandardFolder.find(StandardFolder::MISC_FOLDER_ID)
    StandardFolderStandardDocument.find_each do |sfsd|
      next if sfsd.standard_folder.present?
      sfsd.standard_folder = misc
      if sfsd.save
        puts "#{sfsd.standard_base_document_id} - #{sfsd.standard_base_document.name} is now moved to Miscellaneous"
      end
    end
    puts "Task done. Make sure to purge/regenerate document cache (StandardFolder, StandardDocument)"
  end

  desc "Check empty documents"
  task check_empty_documents: :environment do
    empty_documents = []
    Document.select('id, final_file_key').find_each do |doc|
      if doc.document_owners.select('1').count == 1 &&
          doc.all_sharees_ids_except_system.size == 1 &&
          !doc.document_field_values.select('1').exists? &&
          !doc.pages.select('1').exists? &&
          !doc.final_file_key
        empty_documents << doc.id
      end
    end
    puts "Empty Document Found: #{empty_documents.count}"
    puts "Docs Ids: #{empty_documents.inspect}"
  end

  desc "Check nil base_standard_document_field in DocumentFieldValue"
  task check_invalid_base_standard_document_field: :environment do
    puts DocumentFieldValue.select('local_standard_document_field_id, document_id').select{|e| e.base_standard_document_field.nil? }.map { |s| "#{s.local_standard_document_field_id}, #{s.document_id}, #{s.document.standard_document_id}" }.uniq
  end

  desc "Find standard_document_id associated with a document, but not pointing to any valid standard_document model"
  task :check_docs_standard_document_id => :environment do
    invalid_std_doc_ids = []
    Document.order(id: :asc).where.not(standard_document_id: nil).select("id, standard_document_id").each do |document|
      unless StandardDocument.exists?(id: document.standard_document_id)
        invalid_std_doc_ids << { doc: document.id, std_doc_id: document.standard_document_id }
      end
    end

    Document.order(id: :asc).where.not(suggested_standard_document_id: nil).select("id, suggested_standard_document_id").each do |document|
      unless StandardDocument.exists?(id: document.suggested_standard_document_id)
        invalid_std_doc_ids << { doc: document.id, std_doc_id: document.suggested_standard_document_id }
      end
    end

    puts invalid_std_doc_ids

    File.open("missing_docs_standard_document_id.txt", 'w') do |file|
      invalid_std_doc_ids.uniq.each do |data|
        file.puts "#{data[:doc]} -> #{data[:std_doc_id]}"
      end
    end
  end

  desc "List of standard_document_ids that are missing and unused"
  task :check_standard_document_ids => :environment do
    missing_ids = []
    (1..StandardDocument.where(:consumer_id => nil).count).each do |required_id|
      unless StandardDocument.exists?(id: required_id)
        missing_ids << required_id
      end
    end
    puts missing_ids
    File.open("missing_standard_document_ids.txt", 'w') do |file|
      missing_ids.each do |missing_id|
        file.puts missing_id
      end
    end
  end

  desc "Check duplicated standard_base_document_id in JSON data"
  task :check_duplicated_standard_base_document_ids => :environment do
    docs_structure = JSON.parse(File.read("#{Rails.root}/config/standard_base_documents_structure.json"))
    entries = {}
    docs_structure.each do |category, category_hash|
      category_id = category_hash["id"]
      if entries[category_id].nil?
        entries[category_id] = 1
      else
        puts "Duplicated Category ID found: #{category_id}"
      end
    end
    docs = JSON.parse(File.read("#{Rails.root}/config/standard_base_documents.json"))
    entries = {}
    docs.each do |document, document_hash|
      document_id = document_hash["id"]
      if entries[document_id].nil?
        entries[document_id] = 1
      else
        puts "Duplicated StandardBaseDocument ID found: #{document_id}"
      end
    end
  end

  task :check_invalid_group_users => :environment do
    GroupUser.where.not(user_id: nil).each do |group_user|
      group_user.user.groups_as_owner.each do |group|
        other_group_user = group.group_users.where(user_id: group_user.group.owner_id).first
        if other_group_user.blank?
          puts "Missing other side of group user for user_id: #{group_user.user.id}"
        end
      end
    end
    nil
  end

  desc "Migrate connected group_user for StandardBaseDocumentOwner"
  task :migrate_standard_base_document_owners => :environment do
    StandardBaseDocumentOwner.where(owner_type: "GroupUser").each do |std_doc_owner|
      group_user = GroupUser.find(std_doc_owner.owner_id)
      if group_user.user.present?
        std_doc_owner.owner = group_user.user
        std_doc_owner.save!
      end
    end
  end

  desc "Cleanup stale document field values for deleted custom document fields"
  task :cleanup_document_field_values => :environment do
    DocumentFieldValue.all.select { |fv| fv.base_standard_document_field.nil? }.each do |field_value|
      if field_value.local_standard_document_field_id > 10000 #Standard fields ids are less than 10K
        field_value.destroy
      else
        puts "Error: Standard Field Value being deleted. Doc: #{field_value.document.id}"
      end
    end
  end

end
