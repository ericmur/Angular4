namespace :field_value do
  desc 'Mark DocumentFieldValue to be migrated'
  task prepare_migration: :environment do
    User.update_all(fields_encryption_migration_done: false)
  end

  desc 'Generate field suggestions'
  task generate_user_field_value_suggestions: :environment do
    Document.find_each do |document|
      document.document_owners.only_connected_owners.each do |document_owner|
        document.document_field_values.each do |field_value|
          field = field_value.base_standard_document_field
          next unless field
          next if field.encryption?
          next unless field.suggestions

          FieldValueSuggestion.create_suggestion_for_field(document_owner.owner.id, document.standard_document_id, field.name, field_value.value)
        end
      end
    end
  end
end
