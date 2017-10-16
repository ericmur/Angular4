class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.integer :sender_id
      t.integer :recipient_id, index: true
      t.references :notifiable, polymorphic: true, index: true
      t.boolean :unread, null: false, default: true, index: true
      t.integer :notification_type, index: true
      t.text :message, null: false

      t.timestamps null: false
    end

    add_index :notifications, [:recipient_id, :created_at], name: "notifications_recipient_created_idx"
  end
end
