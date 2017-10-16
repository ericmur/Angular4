class AddEditedAtToMessagableMessages < ActiveRecord::Migration
  def change
    add_column :messages, :edited_at, :datetime
  end
end
