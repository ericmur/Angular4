class AddAdvisorIdToGroupUser < ActiveRecord::Migration
  def change
    add_column :group_users, :advisor_id, :integer
    add_index :group_users, :advisor_id
  end
end
