class StandardFolderStandardDocument < ActiveRecord::Base
  belongs_to :standard_folder
  belongs_to :standard_base_document #Could be file or folder
  
  validates :rank, presence: true

  before_validation :set_rank, :on => :create

  scope :with_parent_folder, lambda { |st_folder_id| 
    where(:standard_folder_id => st_folder_id) 
  }

  scope :only_system_standard_documents, lambda {
    where(:standard_base_documents => { :consumer_id => nil }).joins(:standard_base_document)
  }

  scope :for_consumer, lambda { |consumer|
    joins(:standard_base_document => :owners).where("standard_base_document_owners.owner_id = ? and standard_base_document_owners.owner_type in (?)", consumer.id, ["User", "Consumer"])
  }

  scope :for_non_connected_group_users_of, lambda { |uid|
    guids = User.find_by_id(uid).group_users_as_group_owner.where(:user_id => nil).select(:id).map(&:id)
    if guids.count > 0
      joins(:standard_base_document => :owners).where("standard_base_document_owners.owner_id in (?) and standard_base_document_owners.owner_type in (?)", guids, ["GroupUser"])
    else
      none
    end
  }

  scope :for_connected_group_users_of, lambda { |uid|
    uids = User.find_by_id(uid).group_users_as_group_owner.where.not(:user_id => nil).select(:user_id).map(&:user_id)
    if uids.count > 0
      joins(:standard_base_document => :owners).where("standard_base_document_owners.owner_id in (?) and standard_base_document_owners.owner_type in (?)", uids, ["User", "Consumer"])
    else
      none
    end
  }

  scope :viewable_by_user, -> (user_id) {
    joins(standard_base_document: :permissions).where(permissions: { user_id: user_id, value: Permission::VIEW }).distinct
  }

  def set_rank
    unless self.rank
      highest_rank_row = StandardFolderStandardDocument.with_parent_folder(self.standard_folder_id).order(rank: :desc).first
      self.rank = highest_rank_row ? (highest_rank_row.rank + 1) : 1
    end
  end
end
