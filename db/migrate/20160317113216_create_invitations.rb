class CreateInvitations < ActiveRecord::Migration
  def change
    create_table :invitations do |t|
      t.string :email
      t.string :phone
      t.string :phone_normalized
      t.string :token
      t.datetime :accepted_at
      t.datetime :rejected_at
      t.integer :accepted_by_user_id
      t.integer :created_by_user_id
      t.references :group_user, index: true, foreign_key: true
      t.boolean :email_invitation, default: true, null: false
      t.boolean :text_invitation, default: true, null: false
      t.timestamps null: false
    end
  end
end
