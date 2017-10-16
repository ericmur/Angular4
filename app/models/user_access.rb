require 'transactional_query'

class UserAccess < ActiveRecord::Base
  include TransactionalQuery

  #The accessor is "Head of Household" that has access to all documents of the 
  #user and can share it with other users. He can also upload more documents
  #or delete/update any documents for the user. He is called "Head of Household"
  #in the app.
  #HOWEVER he is not given access at this time to documents shared with this user
  #by another user
  belongs_to :accessor, :class_name => "User"
  belongs_to :user

  def save_with_keys
    self.transactional_save do
      docs = user.document_ownerships.map(&:document)
      docs.each do |doc|
        accessor_key = doc.build_symmetric_key_for_user(:by_user_id => self.user_id, :with_user_id => self.accessor_id)
        accessor_key.save!
      end
    end
  end

  def remove(remove_keys = true)
    self.transactional_destroy do
      if remove_keys
        docs = user.document_ownerships.map(&:document)
        docs.each do |doc|
          accessor_key = doc.symmetric_keys.for_user_access(accessor_id).first
          accessor_key.destroy if accessor_key
        end
      end
    end
  end
end
