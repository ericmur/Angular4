class AddRejectedByUserToInvitations < ActiveRecord::Migration
  def change
    add_column :invitations, :rejected_by_user_id, :integer
    add_column :invitations, :countered_at, :datetime
  end
end
