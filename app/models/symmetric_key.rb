class SymmetricKey < ActiveRecord::Base
  belongs_to :created_by_user, :class_name => "User"
  belongs_to :created_for_user, :class_name => "User"
  belongs_to :document

  validates_associated :created_by_user, :created_for_user
  
  attr_accessor :key
  attr_accessor :iv

  before_save :encrypt_key, :unless => Proc.new { |obj| obj.key.nil? }
  after_save  :clear_key
  after_create :generate_document_permissions
  after_destroy :destroy_document_permissions

  scope :for_user_access, lambda { |uid| where(:created_for_user_id => uid) }
  
  scope :for_document_owned_by, -> (user_id) {
    joins(:document => :document_owners)
    .where(
      "EXISTS (#{DocumentOwner.only_connected_owners
                          .where(DocumentOwner.arel_table[:document_id].eq(Document.arel_table[:id]))
                          .where(owner_id: [user_id].flatten).select("1").to_sql})"
    )
  }
  scope :for_document_not_owned_by, -> (user_id) {
    joins(:document => :document_owners)
    .where(
      "NOT EXISTS (#{DocumentOwner.only_connected_owners
                          .where(DocumentOwner.arel_table[:document_id].eq(Document.arel_table[:id]))
                          .where(owner_id: [user_id].flatten).select("1").to_sql})"
    )
  }

  validates :created_for_user_id, :uniqueness => { :scope => :document_id, :message => "can only be associated once per document" }
  
  def decrypt_key
    pgp = pgp_with_private_key
    pgp.decrypt(self.key_encrypted)
  end

  def decrypt_iv
    #created_for_user_id is nil if this key is for DocytBot.
    pgp = pgp_with_private_key
    
    pgp.decrypt(self.iv_encrypted)
  end

  private
  def pgp_with_private_key
    #created_for_user_id is nil if this key is for DocytBot.
    if self.created_for_user_id.nil?
      pgp = Encryption::Pgp.new({ :password => Rails.startup_password_hash, :private_key => Rails.private_key })
    else
      if Rails.app_type == User::MOBILE_APP
        pgp = Encryption::Pgp.new({ :password => Rails.user_password_hash, :private_key => self.created_for_user.pin_private_key })
      elsif Rails.app_type == User::WEB_APP
        pgp = Encryption::Pgp.new({ :password => self.created_for_user.authentication_token, :private_key => self.created_for_user.auth_token_private_key })
      elsif Rails.app_type == User::DOCYT_BOT_APP
        pgp = Encryption::Pgp.new({ :password => Rails.user_oauth_token, :private_key => self.created_for_user.oauth_token_private_key })
      else
        raise "Invalid app type: #{Rails.app_type}"
      end
    end

    pgp
  end
  
  def encrypt_key
    if self.created_for_user_id.nil?
      pgp = Encryption::Pgp.new({ :public_key => Rails.public_key })
    else
      pgp = Encryption::Pgp.new({ :public_key => self.created_for_user.public_key })
    end
    self.key_encrypted = pgp.encrypt(self.key)
    self.iv_encrypted = pgp.encrypt(self.iv) unless self.iv.nil?
  end

  def clear_key
    self.key = nil
    self.iv = nil
  end

  def generate_document_permissions
    if created_for_user && document
      if document.business_document? && document.document_business_partner?(created_for_user)
        DocumentPermission.create_permissions_if_needed(document, created_for_user, DocumentPermission::BUSINESS_PARTNER)
      else
        DocumentPermission.create_permissions_if_needed(document, created_for_user, DocumentPermission::SHAREE)
      end
    end
  end

  def destroy_document_permissions
    if created_for_user && document
      document.rebuild_document_permissions_for(created_for_user)
    end
  end
end
