class CreateMessages < ActiveRecord::Migration
  def change
    create_table :messages do |t|
      t.references :sender, index: true
      t.references :chat, index: true
      t.text :text
      t.timestamp :read_at
      t.timestamps null: false
    end
  end
end
