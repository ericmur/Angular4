class AddS3ObjectKeyToEmails < ActiveRecord::Migration
  def change
    add_column :emails, :s3_bucket_name, :string
    add_column :emails, :s3_object_key, :string
  end
end
