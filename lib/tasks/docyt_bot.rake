namespace :docyt_bot do
  task :get_fields_slots => :environment do
    puts StandardDocumentField.load_fields.uniq.join("\n")
  end

  task :enumerate_utterances => :environment do
    Intent.load
  end

  task :utterances_csv => :environment do
    Intent.get_csv
  end

  task :enumerate_field_descriptors_for_slots => :environment do
    st_fields = StandardDocumentField.where(:primary_descriptor => true).select(:standard_document_id, :field_id)
    values = []
    st_fields.each do |st_field|
      std_id = st_field.standard_document_id
      doc_field_values = DocumentFieldValue.joins(:document).where(["documents.standard_document_id = ?", std_id]).where(:local_standard_document_field_id => st_field.field_id)
      doc_field_values.each do |doc_field_value|
        values << doc_field_value.value if (doc_field_value and doc_field_value.value)
      end
    end
    puts values.map(&:downcase).uniq.join("\n")
  end

  task :enumerate_list_of_names => :environment do
    names = []
    User.all.each do |u|
      if !u.first_name.blank?
        names << u.first_name 
        names << (u.first_name + "'s")
        names << u.name
        names << (u.name + "'s")
      end
    end

    GroupUser.all.each do |g|
      next if g.user_id
      if !g.first_name.blank?
        names << g.first_name
        names << (g.first_name + "'s")
        names << g.name
        names << (g.name + "'s")
      end
    end

    puts names.uniq.join("\n")
  end
end
