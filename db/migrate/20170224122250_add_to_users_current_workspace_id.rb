class AddToUsersCurrentWorkspaceId < ActiveRecord::Migration
  def change
    add_column :users, :current_workspace_id, :integer
  end
end
