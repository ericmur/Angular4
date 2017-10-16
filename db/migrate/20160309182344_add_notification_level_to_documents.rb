class AddNotificationLevelToDocuments < ActiveRecord::Migration
  def change
    add_column :documents, :notification_level, :integer, default: 0
  end
end
