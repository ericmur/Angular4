class AddIndexToInvitations < ActiveRecord::Migration
  def change
  	add_index :invitations, [:email, :phone_normalized]
  end
end
