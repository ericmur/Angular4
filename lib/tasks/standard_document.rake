namespace :standard_document do
  desc "Create missing standard document and associate with document"
  task :create_for_document, [:name,:description,:with_pages,:standard_folder_id,:document_id] => :environment do |task, args|
    name = args.name
    description = args.description.to_s.blank? ? nil : args.description.to_s.strip
    document_id = args.document_id
    standard_folder_id = args.standard_folder_id
    with_pages = ["true","1"].include?(args.with_pages)

    standard_folder = StandardFolder.find(standard_folder_id)
    document = Document.find(document_id)

    ActiveRecord::Base.transaction(requires_new: true) do
      begin
        unless standard_document = StandardDocument.where(:name => name, :consumer_id => document.consumer_id).first
          standard_document_attributes = {
            name: name,
            description: description,
            with_pages: with_pages,
            default: true,
            consumer_id: document.consumer_id
          }

          standard_document = StandardDocument.new(standard_document_attributes)
          standard_document.owners.build(owner: document.uploader)
          standard_document.standard_folder_standard_documents.build(standard_folder_id: standard_folder.id)
          standard_document.save!
        end
        
        
        document.standard_document = standard_document
        document.save!
        document_owners = document.document_owners.to_a
        User.where(id: document.all_sharees_ids_except_system).each do |current_user|
          document.generate_standard_base_document_permissions
        end
        document.generate_folder_settings
        document_owners.each do |document_owner|
          document_owner.generate_standard_base_document_owner
        end
        puts "Created StandardDocument ID: #{standard_document.id}"
      rescue => e
        puts e.message
        raise ActiveRecord::Rollback
      end
    end
  end

  desc "create fields on a standard document of a document"
  task :add_field, [:document_id,:name,:data_type,:field_id,:type,:notify,:encryption] => :environment do |task, args|
    document = Document.find(args.document_id.to_i)
    standard_document_id = document.standard_document_id
    name = args.name.to_s
    data_type = args.data_type.to_s
    field_id = args.field_id.to_i
    notify = ["true","1"].include?(args.notify)
    type = args.type.to_s
    encryption = ["true","1"].include?(args.encryption)

    data_types = JSON.parse(File.read("#{Rails.root}/config/data_types.json"))
    types = %w[DocumentField StandardDocumentField]

    raise "Invalid `data_type` : #{data_type}" unless data_types.include?(data_type)
    raise "Invalid `type` : #{type}" unless types.include?(type)

    standard_document = StandardDocument.find(standard_document_id)
    created_by_user_id = standard_document.documents.first.consumer_id

    raise "Invalid `created_by_user_id` : nil" if created_by_user_id.blank?

    # field_id # Improvement: verify field_id

    field_attributes = {
      name: name,
      data_type: data_type,
      field_id: field_id,
      min_year: nil,
      max_year: nil,
      type: type,
      notify: notify,
      encryption: encryption,
      created_by_user_id: created_by_user_id,
      document_id: nil
    }

    ActiveRecord::Base.transaction(requires_new: true) do
      begin
        if standard_document.standard_document_fields.find_by_field_id(field_id).nil?
          field = standard_document.standard_document_fields.build(field_attributes)
          if notify
            if data_type == 'due_date'
              NotifyDuration::DEFAULT_DUE_NOTIFY_DURATIONS.each do |n|
                field.notify_durations.build(amount: n[:amount], unit: n[:unit])
              end
            elsif data_type == 'expiry_date'
              NotifyDuration::DEFAULT_EXPIRY_NOTIFY_DURATIONS.each do |n|
                field.notify_durations.build(amount: n[:amount], unit: n[:unit])
              end
            end
          end
          field.save!
        end
        
      rescue => e
        puts e.message
        raise ActiveRecord::Rollback
      end
    end
  end

end
