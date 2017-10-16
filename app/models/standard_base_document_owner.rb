class StandardBaseDocumentOwner < ActiveRecord::Base
  belongs_to :standard_base_document
  belongs_to :owner, polymorphic: true

  validates :standard_base_document_id, uniqueness: { scope: [ :owner_id, :owner_type ] }

  scope :only_connected, -> { where(owner_type: ['User', 'Consumer']) }
  scope :for_user_group_users, -> (user) { where(owner_type: 'GroupUser').where(owner_id: user.group_users_as_group_owner.where(user_id: nil).map(&:id)) }
  scope :not_for_user_group_users, -> (user) { where(owner_type: 'GroupUser').where.not(owner_id: user.group_users_as_group_owner.where(user_id: nil).map(&:id)) }
end
