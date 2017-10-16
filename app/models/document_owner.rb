class DocumentOwner < ActiveRecord::Base
  belongs_to :document
  belongs_to :owner, :polymorphic => true #Could be consumer or group_user or client

  validates :document_id, :uniqueness => { :scope => [:owner_id, :owner_type] }
  scope :only_connected_owners, lambda {
    where(:owner_type => 'User')
  }
  scope :only_not_connected_owners, lambda {
    where(:owner_type => 'GroupUser')
  }
  scope :by_owners, lambda { |os|
    cond = os.map { |o|
      if "User" == o.class.to_s
        "(owner_id = #{o.id} and owner_type = 'User')"
      else
        "(owner_id = #{o.id} and owner_type = '#{o.class.to_s}')"
      end
   }.join(" or ")
    where(cond)
  }

  after_create :generate_standard_base_document_owner
  after_create :generate_document_permissions
  after_destroy :destroy_document_permissions
  after_destroy :destroy_document_access_requests

  def owner_name
    if consumer?
      User.find(owner_id).first_name
    else
      self.owner.name.split(' ').first
    end
  end

  def connected?
    consumer?
  end

  def user_id
    if self.consumer?
      owner_id
    else
      owner.user_id
    end
  end

  def owner_or_uploader_id
    if self.consumer?
      owner_id
    else
      owner.user_id ? owner.user_id : self.document.uploader_id
    end
  end

  def consumer?
    self.owner_type == User.to_s
  end

  def group_user?
    self.owner_type == GroupUser.to_s
  end

  def client?
    self.owner_type == Client.to_s
  end

  def generate_document_permissions
    assigned_owner = nil
    document_permission_type = nil

    if connected?
      assigned_owner = owner
      document_permission_type = DocumentPermission::OWNER
    elsif owner.class.name == 'GroupUser'
      assigned_owner = owner.group.owner
      document_permission_type = DocumentPermission::CUSTODIAN
    elsif owner.class.name == 'Client'
      if owner.connected? # This is only for safeguard. For connected case will be handled on above first `connected?` condition
        assigned_owner = owner.consumer
        document_permission_type = DocumentPermission::OWNER
      else
        assigned_owner = owner.advisor
        document_permission_type = DocumentPermission::CUSTODIAN
      end
    else
      raise "Invalid owner_type: #{owner_type} for Document: #{document_id}, Owner: #{owner_id}"
    end
    DocumentPermission.create_permissions_if_needed(document, assigned_owner, document_permission_type)
  end

  # When destroying document permissions for owner, we need to check if owner are still the uploader or other roles.
  # For this reason, we will actually reset the permission for current owner and rebuild
  def destroy_document_permissions
    if connected?
      document.rebuild_document_permissions_for(owner)
    elsif owner.class.name == 'GroupUser'
      document.rebuild_document_permissions_for(owner.group.owner)
    elsif owner.class.name == 'Client'
      if owner.connected? # This is only for safeguard. For connected case will be handled on above first `connected?` condition
        document.rebuild_document_permissions_for(owner.consumer)
      else
        document.rebuild_document_permissions_for(owner.advisor)
      end
    end
  end

  def generate_standard_base_document_owner
    standard_document = self.document.standard_document
    return unless (standard_document and standard_document.consumer_id.present?)

    unless standard_document.owners.where(owner: self.owner).exists?
      standard_document.owners.create(owner: self.owner)
    end

    standard_document.standard_folder_standard_documents.each do |sfsd|
      standard_folder = sfsd.standard_folder
      next unless standard_folder.consumer_id.present?
      unless standard_folder.owners.where(owner: self.owner).exists?
        standard_folder.owners.create(owner: self.owner)
      end
    end
  end

  private

  def destroy_document_access_requests
    self.document.document_access_requests.created_by(self.owner_id).destroy_all if self.connected?
  end
end
