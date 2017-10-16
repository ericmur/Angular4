class AddStateIndexToInvitations < ActiveRecord::Migration
  def change
  	add_index :invitations, :state
  end
end
