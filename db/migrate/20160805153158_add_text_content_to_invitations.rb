class AddTextContentToInvitations < ActiveRecord::Migration
  def change
    add_column :invitations, :text_content, :text
  end
end
