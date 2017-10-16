class AddUserContactListToUserContacts < ActiveRecord::Migration
  def change
    add_reference :user_contacts, :user_contact_list, index: true, foreign_key: true
    remove_column :user_contacts, :user_id, :integer
  end
end
