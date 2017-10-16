class AddNotificationLevelToDocumentFieldValues < ActiveRecord::Migration
  def change
    add_column :document_field_values, :notification_level, :integer, default: 0
  end
end
