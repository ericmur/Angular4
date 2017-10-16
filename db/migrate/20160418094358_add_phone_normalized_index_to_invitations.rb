class AddPhoneNormalizedIndexToInvitations < ActiveRecord::Migration
  def change
    add_index :invitations, [:phone_normalized]
  end
end
