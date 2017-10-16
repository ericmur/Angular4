class AddBusinessIdToClients < ActiveRecord::Migration
  def change
    add_reference :clients, :business, index: true, foreign_key: true
    add_reference :group_users, :business, index: true, foreign_key: true
  end
end
