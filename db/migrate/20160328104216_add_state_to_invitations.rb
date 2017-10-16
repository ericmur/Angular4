class AddStateToInvitations < ActiveRecord::Migration
  def up
    add_column :invitations, :state, :string
    Invitationable::Invitation.update_all(state: 'pending')
  end

  def down
    remove_column :invitations, :state, :string
  end
end
