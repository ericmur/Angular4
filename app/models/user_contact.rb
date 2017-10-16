class UserContact < ActiveRecord::Base
  belongs_to :user_contact_list
  serialize :emails, Array
  serialize :phones, Array
end
