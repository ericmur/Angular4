class AddProfileBackgroundToGroupUsers < ActiveRecord::Migration
  def change
    add_column :group_users, :profile_background, :string
  end
end
