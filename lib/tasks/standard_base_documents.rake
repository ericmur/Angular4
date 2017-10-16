namespace :standard_base_documents do
  task :load => :environment do
    StandardBaseDocument.load
    FirstTimeStandardDocument.load
  end

  desc "Regenerate owners from document owners"
  task generate_owners: :environment do
    DocumentOwner.find_each {|d| d.generate_standard_base_document_owner }
  end

  desc "Generate permissions for Custom StandardBaseDocument"
  task generate_permissions: :environment do
    StandardBaseDocument.only_custom.find_each do |standard_document|
      standard_document.default = true
      standard_document.save!
      standard_document.owners.where(owner_type: 'GroupUser').each do |std_doc_owner|
        group_owner = std_doc_owner.owner.group.owner
        Permission::VALUES.each do |value|
          next if standard_document.permissions.where(user: group_owner, folder_structure_owner: std_doc_owner.owner, value: value).exists?
          standard_document.permissions.create!(
            user: group_owner,
            folder_structure_owner: std_doc_owner.owner,
            value: value
          )
        end
      end
      connected_owners = standard_document.owners.where.not(owner_type: 'GroupUser').where.not(owner_type: 'Client').to_a

      connected_owners.each do |o1|
        Permission::VALUES.each do |value|
          next if standard_document.permissions.where(user: o1.owner, folder_structure_owner: o1.owner, value: value).exists?
          standard_document.permissions.create!(
            user: o1.owner,
            folder_structure_owner: o1.owner,
            value: value
          )
        end

        connected_owners.each do |o2|
          next unless o1.owner.group_users_as_group_owner.where(user_id: o2.owner.id).exists?
          Permission::VALUES.each do |value|
            next if standard_document.permissions.where(user: o1.owner, folder_structure_owner: o2.owner, value: value).exists?
            standard_document.permissions.create!(
              user: o1.owner,
              folder_structure_owner: o2.owner,
              value: value
            )
          end
        end
      end
    end

    Document.joins(:standard_document).where.not(standard_base_documents: { consumer_id: nil }).find_each do |doc|
      doc.symmetric_keys.each do |symmetric_key|
        next if symmetric_key.created_for_user_id.blank? || symmetric_key.created_by_user_id.blank?
        doc.generate_standard_base_document_permissions
      end
    end
  end

  desc "Verify missing standard folder"
  task verify_missing_standard_folder: :environment do
    c = StandardFolderStandardDocument.all.select{|f| f.standard_folder.nil? }.count
    if c > 0
      puts "Found #{c} missing StandardFolder"
    else
      puts "No missing StandardFolder found"
    end
  end

  #185 => 184 (Customer_Invoice => Invoice)
  #186 => 184 (MISC Invoice => Invoice)
  #244 => 170
  #Ignore Fields migration
  task :migrate_standard_docs, [:from_id, :to_id] => :environment do
    StandardDocument.where(:id => args[:from_id]).first.documents.each do |d|
      d.standard_document_id = args[:to_id]
      d.save!
    end
  end

  task :one_time_migrations_for_group_users => :environment do
    #Migrate over to setup created_for for when consumer_id is nil
    StandardBaseDocument.where.not(:consumer_id => nil).each do |sbd|
      unless sbd.owners.find_by(:owner_id => sbd.consumer_id, :owner_type => [User.to_s])
        sbd.owners.create!(:owner => sbd.created_by)
      end
    end

    Document.where.not(:consumer_id => nil).each do |doc|
      unless doc.document_owners.find_by(:owner_id => doc.consumer_id, :owner_type => [User.to_s])
        doc.document_owners.create!(:owner => doc.consumer)
      end
    end
  end

  task :setup_types_for_fields => :environment do
    BaseDocumentField.where(:type => nil).each do |base_doc_field|
      base_doc_field.type = 'StandardDocumentField'
      base_doc_field.save!
    end
  end

  desc "Check missing standard_base_document_account_types"
  task check_missing_standard_base_document_account_types: :environment do
    StandardBaseDocument.find_each do |doc|
      if doc.standard_base_document_account_types.empty?
        puts "%-8s %-30s %-20s" % ["#{doc.id}", doc.name, "(#{doc.owners.map(&:owner_type).uniq.join(',')})"]
      end
    end
  end

  desc "Fix folder setting for existsing document"
  task :setup_folder_settings_for_existing_users => :environment do
    User.all.each do |consumer|
      acc_type = consumer.consumer_account_type
      if acc_type.nil?
        consumer.consumer_account_type = ConsumerAccountType.individual_type.first
        consumer.save!
        acc_type = consumer.consumer_account_type
      end

      consumer.group_users_as_group_owner.each do |group_user|
        group_user.generate_folder_settings(consumer, group_user.label)
      end
    end
  end

  desc "Generate folder settings for existing clients for advisor"
  task :setup_folder_settings_for_existing_clients => :environment do
    User.where.not(standard_category_id: nil).each do |advisor|
      acc_type = advisor.consumer_account_type
      if acc_type.nil?
        advisor.consumer_account_type = ConsumerAccountType.where(id: ConsumerAccountType::BUSINESS).first
        advisor.save!
        acc_type = advisor.consumer_account_type
      end
      
      advisor.clients_as_advisor.each do |client|
        client.generate_folder_settings(advisor)
      end
    end
  end

  desc "Fix folder setting for existsing document"
  task setup_folder_settings_for_existing_documents: :environment do
    Document.where.not(standard_document_id: nil).find_each do |document|
      document.generate_folder_settings unless document.standard_document.nil?
    end
  end

  #StandardFolderStandardDocument.all.map {|sfsd| [sfsd.standard_folder, sfsd.standard_folder_id, sfsd.id, sfsd.standard_base_document.consumer_id] }.select{|k| k.first.nil? }.map { |s| [s.last, s[2], s[1]] } - will list all missing standard_folders
  task :create_standard_folder, [:phone, :folder_id, :folder_name] => :environment do |t, args|
    u = User.where(:phone_normalized => PhonyRails.normalize_number(args[:phone].try(:strip), :country_code => 'US')).first
    raise 'No user found' if u.nil?
    standard_folder = StandardFolder.new(:name => args[:folder_name], :description => args[:folder_name], :created_by => u, :id => args[:folder_id].to_i, :rank => StandardFolder.where(consumer_id: nil).maximum('rank'), :category => true, :icon_name_2x => "Misc_icon@2x.png", :icon_name_3x => "Misc_icon@3x.png")
    standard_folder.owners.build(owner: u) unless standard_folder.owners.where(:owner_id => u.id, :owner_type => 'User').first
    standard_folder.save!

    if ufs = UserFolderSetting.where(:user_id => u.id, :folder_owner_id => u.id, :folder_owner_type => 'User', :standard_base_document_id => args[:folder_id]).first
      ufs.displayed = true
      ufs.save!
    else
      UserFolderSetting.create!(:user_id => u.id, :folder_owner_id => u.id, :folder_owner_type => 'User', :standard_base_document_id => args[:folder_id], :displayed => true)
    end
  end

  task :make_new_system_folder_visible, [:folder_name] => :environment do |t, args|
    sfs = StandardFolder.where(:name => args[:folder_name], :consumer_id => nil)
    raise "More than one standard folder found for #{args[:folder_name]}. Check why is that before proceeding" if sfs.count > 1
    sf = sfs.first
    User.all.each do |u|
      if ufs = UserFolderSetting.where(:user_id => u.id, :standard_base_document_id => sf.id, :folder_owner_id => u.id, :folder_owner_type => 'User').first
        ufs.displayed = true
        ufs.save!
      else
        ufs = UserFolderSetting.create!(:user_id => u.id, :standard_base_document_id => sf.id, :folder_owner_id => u.id, :folder_owner_type => 'User', :displayed => true)
      end

      u.group_users_as_group_owner.each do |group_user|
        if ufs = UserFolderSetting.where(:user_id => u.id, :standard_base_document_id => sf.id, :folder_owner_id => group_user.id, :folder_owner_type => 'GroupUser').first
          ufs.displayed = true
          ufs.save!
        else
          ufs = UserFolderSetting.create!(:user_id => u.id, :standard_base_document_id => sf.id, :folder_owner_id => group_user.id, :folder_owner_type => 'GroupUser', :displayed => true)
        end
      end
    end
  end
end
