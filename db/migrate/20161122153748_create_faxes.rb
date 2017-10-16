class CreateFaxes < ActiveRecord::Migration
  def change
    create_table :faxes do |t|
      t.string  :status
      t.string  :fax_number
      t.integer :sender_id
      t.integer :document_id

      t.timestamps null: false
    end
    add_index :faxes, [:document_id, :sender_id]
  end
end
