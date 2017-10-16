class CreateCloudServiceAuthorizations < ActiveRecord::Migration
  def change
    create_table :cloud_service_authorizations do |t|
      t.references :user, index: true
      t.references :cloud_service, index: true
      t.string :uid
      t.string :encrypted_token
      t.string :encrypted_token_salt
      t.string :encrypted_token_iv
      t.timestamps
    end
  end
end