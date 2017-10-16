namespace :user_migrations do
  task :img_to_pdf_migration_entries => :environment do |t, args|
    User.all.each do |u|
      m = u.build_user_migration
      m.save!
    end
  end

  task :trigger_img_to_pdf_migration, [:document_id] => :environment do |t, args|
    if args[:document_id]
      d = Document.find(args[:document_id])
      u = User.find_by_id(d.consumer_id)
      if u
        user_migration = u.user_migration
        user_migration.img_to_pdf_conversion_done = false
        user_migration.save!
      end
    else
      UserMigration.all.each do |u|
        u.img_to_pdf_conversion_done = false
        u.save!
      end
    end
  end

  task :trigger_first_page_thumbnail_creation => :environment do |t, args|
    UserMigration.all.each do |u|
      u.first_page_thumbnail_migration_done = false
      u.save!
    end
  end

  task :create_pages_from_cloud_service_file_and_upload, [:document_id] => :environment do |t, args|
    d = Document.find(args[:document_id])
    raise "Document #{d.id} doesn't contain attached .pdf document" if d.final_file_key.blank?
    raise "DocytBot has no access to document" if d.symmetric_keys.for_user_access(nil).first.nil?
    sources = d.pages.order("page_num ASC").map(&:source)
    d.pages.destroy_all
    DocumentFormatConverters::PdfToImagesConverter.new(d).convert
    d.pages.order("page_num ASC").each_with_index { |p, i|
      p.source = sources[i]
      p.save!
    }
  end

  task :create_upload_emails_for_users => :environment do |t, args|
    User.all.each do |u|
      u.generate_upload_email_in_background
    end
  end

  task :re_encrypt_advisor_documents_and_field_values, [:advisor_id] => :environment do |t, args|
    u=User.where(:id => args[:advisor_id]).first
    SymmetricKey.for_user_access(u).each do |symm_key|
      created_for_user = User.where(:id => symm_key.created_for_user_id).first
      pgp = Encryption::Pgp.new({ :password => Rails.startup_password_hash, :private_key => created_for_user.private_key })
      new_pgp = Encryption::Pgp.new({ :public_key => created_for_user.public_key })
      key = pgp.decrypt(symm_key.key_encrypted)
      symm_key.key_encrypted = new_pgp.encrypt(key)
      if symm_key.iv_encrypted
        iv = pgp.decrypt(symm_key.iv_encrypted)
        symm_key.iv_encrypted = new_pgp.encrypt(iv)
      end
      symm_key.save!
    end
  end

  task :set_advisor_password_and_password_private_key, [:advisor_id, :password] => :environment do |t, args|
    u=User.where(:id => args[:advisor_id]).first
    u.password = args[:password]
    u.password_confirmation = args[:password]
    pgp = Encryption::Pgp.new(:private_key => u.private_key, :password => Rails.startup_password_hash)
    new_pgp = Encryption::Pgp.new(:private_key => pgp.unencrypted_private_key, :password => u.password_hash(u.password))
    u.password_private_key = new_pgp.private_key
    u.save!
  end

  desc "For Advisors who have not yet used the iPhone app, we can use this rake task to set their PIN for iPhone access"
  task :set_advisor_pin_private_key, [:advisor_id, :pin] => :environment do |t, args|
    u=User.where(:id => args[:advisor_id]).first
    u.pin = args[:pin]
    u.pin_confirmation = args[:pin_confirmation]
    u.app_type = User::MOBILE_APP
    pgp = Encryption::Pgp.new(:private_key => u.private_key, :password => Rails.startup_password_hash)
    new_pgp = Encryption::Pgp.new(:private_key => pgp.unencrypted_private_key, :password => u.password_hash(u.pin))
    u.private_key = new_pgp.private_key
    u.save!
  end

  desc "Add ConsumerAccountType to existing Advisors"
  task :add_consumer_account_type, [:advisor_id] => :environment do |t, args|
    u = User.where(:id => args[:advisor_id]).first
    u.consumer_account_type_id = ConsumerAccountType::BUSINESS
    u.save!

    UserFolderSetting.setup_folder_setting_for_user(u)
  end

  desc "Cleanup chats that have nil chats_users_relations"
  task :clean_chats_relations => :environment do
    Chat.all.each do |chat|
      chat.chats_users_relations.where(:chatable_id => nil).destroy_all
      if chat.chats_users_relations.count <= 1
        puts "Destroy chat: #{chat.inspect},  #{chat.chats_users_relations.inspect}"
        chat.destroy
      end
    end
  end

  desc "Migrate birth certificate date field"
  task :migrate_birth_certificate, [:document_id, :date, :time] => :environment do |t, args|
    if args[:date].blank?
      fv = DocumentFieldValue.joins(:document).where("documents.standard_document_id = 24").where(:local_standard_document_field_id => 4, :document_id => args[:document_id]).first
      fv.destroy
    else
      fv = DocumentFieldValue.joins(:document).where("documents.standard_document_id = 24").where(:local_standard_document_field_id => 4, :document_id => args[:document_id]).first
      fv.input_value = args[:date]
      fv.save!
    end

    if args[:time]
      d = Document.find(args[:document_id])
      fv = d.document_field_values.build(:local_standard_document_field_id => 7)
      fv.input_value = args[:time]
      fv.save!
    end
  end

  desc "Migrate Medical Receipts"
  task :migrate_medical_receipts, [:document_id] => :environment do |t, args|
    d = Document.find(args[:document_id])
    d.standard_document_id = 169
    d.save!
    

    if d.document_field_values.where(:local_standard_document_field_id => 6).first.nil?
      fv = d.document_field_values.build(:local_standard_document_field_id => 6)
      fv.input_value = "Medical"
      fv.save!
    else
      puts "Field Value Receipt Type already exists"
    end

    #Remove "Procedure" field
    fv = d.document_field_values.where(:local_standard_document_field_id => 3).first
    fv.destroy if fv

    #Amoutn field
    fv = d.document_field_values.where(:local_standard_document_field_id => 5).first
    if fv
      fv.local_standard_document_field_id = 3
      fv.input_value = fv.value
      fv.save!
    end

    fv = d.document_field_values.where(:local_standard_document_field_id => 4).first
    if fv
      fv.local_standard_document_field_id = 5
      fv.input_value = fv.value
      fv.save!
    end
  end

  desc "Migrate School Receipts"
  task :migrate_school_receipts, [:document_id] => :environment do |t, args|
    d = Document.find(args[:document_id])
    d.standard_document_id = 169
    d.save!
    

    if d.document_field_values.where(:local_standard_document_field_id => 6).first.nil?
      fv = d.document_field_values.build(:local_standard_document_field_id => 6)
      fv.input_value = "Education"
      fv.save!
    else
      puts "Field Value Receipt Type already exists"
    end

    #Remove "Receipt Period Start" field
    fv = d.document_field_values.where(:local_standard_document_field_id => 2).first
    fv.destroy if fv

    #Remove "Receipt Period End" field
    fv = d.document_field_values.where(:local_standard_document_field_id => 3).first
    fv.destroy if fv
    
    #Amount field
    fv = d.document_field_values.where(:local_standard_document_field_id => 4).first
    if fv
      fv.local_standard_document_field_id = 3
      fv.input_value = fv.value
      fv.save!
    end
  end

  desc "Migrate Daycare Receipts"
  task :migrate_daycare_receipts, [:document_id] => :environment do |t, args|
    d = Document.find(args[:document_id])
    d.standard_document_id = 169
    d.save!
    

    if d.document_field_values.where(:local_standard_document_field_id => 6).first.nil?
      fv = d.document_field_values.build(:local_standard_document_field_id => 6)
      fv.input_value = "Childcare"
      fv.save!
    else
      puts "Childcare Receipt Type already exists"
    end

    #Remove "Service Start"/"Service End" field
    fv = d.document_field_values.where(:local_standard_document_field_id => 2).first
    fv.destroy if fv
    fv = d.document_field_values.where(:local_standard_document_field_id => 3).first
    fv.destroy if fv

    #Amount field
    fv = d.document_field_values.where(:local_standard_document_field_id => 4).first
    if fv
      fv.local_standard_document_field_id = 3
      fv.input_value = fv.value
      fv.save!
    end
  end

  desc "Migrate Furniture Receipts"
  task :migrate_furniture_receipts, [:document_id] => :environment do |t, args|
    d = Document.find(args[:document_id])
    d.standard_document_id = 169
    d.save!
    

    if d.document_field_values.where(:local_standard_document_field_id => 6).first.nil?
      fv = d.document_field_values.build(:local_standard_document_field_id => 6)
      fv.input_value = "Household"
      fv.save!
    else
      puts "Household Receipt Type already exists"
    end

    #Remove "Item" field
    fv = d.document_field_values.where(:local_standard_document_field_id => 4).first
    fv.destroy if fv
  end

  desc "Migrate Electronics Manuals"
  task :migrate_electronics_manual, [:document_id] => :environment do |t, args|
    d = Document.find(args[:document_id])
    d.standard_document_id = 195
    d.save!

    if d.document_field_values.where(:local_standard_document_field_id => 5).first.nil?
      fv = d.document_field_values.build(:local_standard_document_field_id => 5)
      fv.input_value = "Electronics"
      fv.save!
    else
      puts "Electronics Manual Type already exists"
    end
  end

  desc "Migrate Furniture Manuals"
  task :migrate_furniture_manual, [:document_id] => :environment do |t, args|
    d = Document.find(args[:document_id])
    d.standard_document_id = 195
    d.save!

    if d.document_field_values.where(:local_standard_document_field_id => 5).first.nil?
      fv = d.document_field_values.build(:local_standard_document_field_id => 5)
      fv.input_value = "Furniture"
      fv.save!
    else
      puts "Furniture Manual Type already exists"
    end
  end

  desc "Migrate Appliance Manuals"
  task :migrate_appliance_manual, [:document_id] => :environment do |t, args|
    d = Document.find(args[:document_id])
    d.standard_document_id = 195
    d.save!

    if d.document_field_values.where(:local_standard_document_field_id => 5).first.nil?
      fv = d.document_field_values.build(:local_standard_document_field_id => 5)
      fv.input_value = "Appliances"
      fv.save!
    else
      puts "Appliances Manual Type already exists"
    end
  end

end
