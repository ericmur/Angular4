class DropUserHiddenFolders < ActiveRecord::Migration
  def change
    drop_table :user_hidden_folders
  end
end
