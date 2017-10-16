class AddPasscodeToDevice < ActiveRecord::Migration
  def change
    add_column :devices, :pass_code, :text
  end
end
