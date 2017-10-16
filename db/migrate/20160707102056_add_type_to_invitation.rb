class AddTypeToInvitation < ActiveRecord::Migration
  def change
    add_column :invitations, :type, :string
  end
end
