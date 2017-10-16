class AddAssociationClientToInvitation < ActiveRecord::Migration
  def change
    add_reference :invitations, :client, index: true
    add_foreign_key :invitations, :clients
  end
end
