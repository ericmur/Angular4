class CreateUserContacts < ActiveRecord::Migration
  def change
    create_table :user_contacts do |t|
      t.references :user, index: true
      t.text :name
      t.text :emails
      t.text :phones

      t.timestamps null: false
    end
  end
end
