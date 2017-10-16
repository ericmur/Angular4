class AddInviteeTypeToInvitations < ActiveRecord::Migration
  def change
    add_column :invitations, :invitee_type, :string, index: true
  end
end
