class CreateClients < ActiveRecord::Migration
  def change
    create_table :clients do |t|
      t.integer :advisor_id
      t.string  :name
      t.string  :email
      t.string  :phone
      t.string  :phone_normalized
      t.references :consumer
      t.timestamps
    end

    add_index :clients, [:advisor_id, :consumer_id]
  end
end
