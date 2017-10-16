class RemoveNotificationLevelFromDocuments < ActiveRecord::Migration
  def change
    remove_column :documents, :notification_level, :integer, default: 0
  end
end
