class AddStructureTypeToGroupUsers < ActiveRecord::Migration
  def change
    add_column :group_users, :structure_type, :string, default: 'flat'
  end
end
