class RemoveCounteredAtFromInvitations < ActiveRecord::Migration
  def change
  	remove_column :invitations, :countered_at, :datetime
  end
end
