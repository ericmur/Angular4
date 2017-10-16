#Details here: https://docytinc.atlassian.net/wiki/pages/viewpage.action?pageId=55480253
class DocumentPermission < ActiveRecord::Base
  VIEW='VIEW'
  EDIT='EDIT'
  EDIT_OWNER='EDIT_OWNER'
  EDIT_SHAREE='EDIT_SHAREE'
  SHARE='SHARE'
  DELETE='DELETE'
  VALUES = [VIEW, EDIT, EDIT_OWNER, EDIT_SHAREE, SHARE, DELETE]

  BUSINESS_PARTNER='BUSINESS_PARTNER'
  OWNER='OWNER'
  UPLOADER='UPLOADER'
  CUSTODIAN='CUSTODIAN'
  SHAREE='SHAREE'
  PREPARER_FOR_CLIENT='PREPARER_FOR_CLIENT'
  PREPARER_FOR_CLIENT_CONTACT='PREPARER_FOR_CLIENT_CONTACT'
  USER_TYPES = [BUSINESS_PARTNER, OWNER, UPLOADER, CUSTODIAN, SHAREE, PREPARER_FOR_CLIENT, PREPARER_FOR_CLIENT_CONTACT]

  belongs_to :user
  belongs_to :document

  validates :user_id, presence: true
  validates :value, presence: true
  validates :value, inclusion: { in: VALUES }

  # we still also store user_type as reference for what user type we are assigning
  validates :user_type, presence: true
  validates :user_type, inclusion: { in: USER_TYPES }

  scope :for_user_id, -> (user_id) { where(user_id: user_id) }

  def self.permission_types_for(user_type)
    case user_type
    when BUSINESS_PARTNER
      VALUES
    when OWNER
      VALUES
    when UPLOADER
      [VIEW, EDIT, EDIT_OWNER, SHARE, DELETE]
    when CUSTODIAN
      VALUES
    when SHAREE
      [VIEW]
    when PREPARER_FOR_CLIENT
      [VIEW, EDIT, EDIT_OWNER, SHARE, DELETE]
    when PREPARER_FOR_CLIENT_CONTACT
      [VIEW, EDIT, EDIT_OWNER, SHARE, DELETE]
    else
      raise 'invalid user type'
    end
  end

  def self.create_permissions_if_needed(document, user, user_type)
    values = self.permission_types_for(user_type)
    values.each do |v|
      unless DocumentPermission.where(document: document, user: user, value: v).exists?
        DocumentPermission.create!(document: document, user: user, value: v, user_type: user_type)
      end
    end
  end

end
