class AddUnlinkedAtToGroupUsers < ActiveRecord::Migration
  def change
    add_column :group_users, :unlinked_at, :datetime
  end
end
