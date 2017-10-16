class RemoveAdvisorIdFromGroupUsers < ActiveRecord::Migration
  def change
    remove_column :group_users, :advisor_id
  end
end
