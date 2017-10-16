class AddFieldsEncryptionMigrationToUsers < ActiveRecord::Migration
  def up
    add_column :users, :fields_encryption_migration_done, :boolean, default: true
    User.update_all(fields_encryption_migration_done: false)
  end

  def down
    remove_column :users, :fields_encryption_migration_done, :boolean
  end
end
