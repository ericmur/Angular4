class CloudServiceAuthorization < ActiveRecord::Base
  belongs_to :user
  belongs_to :cloud_service
  has_many :cloud_service_paths, :dependent => :destroy
  has_many :documents, :dependent => :nullify #If documents have been categorized and approved, we cannot delete them

  validates :cloud_service_id, uniqueness: { scope: :uid }
  validates :token, presence: true
  validates :uid, presence: true #Some identification for this user in the cloud service. In the case of dropbox/drive it is email. In case of some other cloud service it could be a username of some sort

  attr_accessor :token
  attr_encrypted :token, :key => :encryption_key, :mode => :per_attribute_iv_and_salt

  def encryption_key
    Rails.startup_password_hash
  end

end
