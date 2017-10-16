class AddUploadEmailToUser < ActiveRecord::Migration
  def change
    add_column :users, :upload_email, :string
  end
end
