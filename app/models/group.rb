class Group < ActiveRecord::Base
  belongs_to :standard_group
  has_many :group_users, :dependent => :destroy

  #Each user has his own group. Basically each family member will have his own group where he decides who will be in his family group.
  belongs_to :owner, :class_name => 'User'
  validates :standard_group_id, presence: true
  validates :owner_id, :uniqueness => { :scope => :standard_group_id }
end
