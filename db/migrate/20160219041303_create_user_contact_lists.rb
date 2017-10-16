class CreateUserContactLists < ActiveRecord::Migration
  def change
    create_table :user_contact_lists do |t|
      t.references :user, index: true, foreign_key: true
      t.string :state
      t.integer :uploaded_offset, default: 0
      t.integer :max_entries, default: 0
      t.string :type

      t.timestamps null: false
    end
  end
end
