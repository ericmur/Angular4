class CreateMessageUsers < ActiveRecord::Migration
  def change
    create_table :message_users do |t|
      t.string     :receiver_type
      t.integer    :receiver_id
      t.datetime   :read_at
      t.references :message, index: true

      t.timestamps null: false
    end
  end
end
