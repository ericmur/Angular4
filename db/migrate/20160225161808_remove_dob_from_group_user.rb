class RemoveDobFromGroupUser < ActiveRecord::Migration
  def change
    remove_column :group_users, :dob, :string
  end
end
