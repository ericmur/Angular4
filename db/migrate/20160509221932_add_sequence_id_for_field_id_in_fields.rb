class AddSequenceIdForFieldIdInFields < ActiveRecord::Migration
  def change
    execute(%q{
      CREATE SEQUENCE standard_document_fields_field_id_seq START 10001;
      ALTER SEQUENCE standard_document_fields_field_id_seq OWNED BY standard_document_fields.field_id;
      ALTER TABLE standard_document_fields ALTER COLUMN field_id SET DEFAULT nextval('standard_document_fields_field_id_seq');
      ALTER TABLE standard_document_fields ALTER COLUMN field_id SET NOT NULL;
    }) #Assuming we will have a maximum of 1000 standard fields in one document. Beyond that point will be consumer provided fields.
  end
end
