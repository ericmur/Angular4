class AddErrorMessageToFaxes < ActiveRecord::Migration
  def change
    add_column :faxes, :error_message, :string
  end
end
