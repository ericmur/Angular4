class GroupUserAdvisor < ActiveRecord::Base
  belongs_to :advisor, class_name: 'User', foreign_key: 'advisor_id'
  belongs_to :group_user

  validates_associated :group_user
  validates_associated :advisor
end
