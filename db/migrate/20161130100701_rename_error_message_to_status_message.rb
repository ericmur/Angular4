class RenameErrorMessageToStatusMessage < ActiveRecord::Migration
  def change
    rename_column :faxes, :error_message, :status_message
  end
end
