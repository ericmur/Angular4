class AddBusinessInformationIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :business_information_id, :integer
  end
end
