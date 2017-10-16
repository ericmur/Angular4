class AddCurrentWorkspaceTypeToUsers < ActiveRecord::Migration
  def change
    add_column :users, :current_workspace_name, :string
  end
end
