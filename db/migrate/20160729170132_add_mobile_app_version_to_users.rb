class AddMobileAppVersionToUsers < ActiveRecord::Migration
  def change
    add_column :users, :mobile_app_version, :string, index: true
  end
end
