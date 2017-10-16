class RemoveForeignKeyConstraint < ActiveRecord::Migration
  def change
    remove_foreign_key :standard_document_fields, :column => 'created_by_user_id'
  end
end
