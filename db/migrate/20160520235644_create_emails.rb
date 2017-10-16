class CreateEmails < ActiveRecord::Migration
  def change
    create_table :emails do |t|
      t.references :user, :index => true
      t.string :from_address, :null => false
      t.text   :to_addresses, :null => false
      t.text   :subject
      t.text   :body_text
      t.text   :body_html
      t.timestamps null: false
    end
  end
end
