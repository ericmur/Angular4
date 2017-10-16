class StandardFolder < StandardBaseDocument
  MISC_FOLDER_ID = 9019
  BUSINESS_INVOICES_ID = 9020
  PASSWORD_FOLDER_ID = 9023
  BIZ_PASSWORD_FOLDER_ID = 9026
  BUFFET_FOR_FUTURE_SYSTEM_FOLDER_RANK = 1000
  has_many :standard_folder_standard_documents, :dependent => :destroy
  has_many :user_folder_settings, foreign_key: 'standard_base_document_id'
  has_many :advisor_default_folders, :dependent => :destroy

  validates :rank, :presence => true, :if => Proc.new { |obj| obj.category? }
  before_validation :set_rank, :on => :create

  scope :only_category, -> { where(category: true) }
  scope :for_owner, -> (owner_id, owner_type) {
    owner_type = ['User', 'Consumer'] unless owner_type == 'GroupUser'
    joins(:owners).where(standard_base_document_owners: { owner_id: owner_id, owner_type: owner_type })
  }
  scope :for_user_non_connected_group_users, -> (user) {
    joins(:owners).where(standard_base_document_owners: { owner_id: user.group_users_as_group_owner.where(user_id: nil).map(&:id), owner_type: 'GroupUser' })
  }
  scope :for_user_connected_group_users, -> (user) {
    joins(:owners).where(standard_base_document_owners: { owner_id: user.group_users_as_group_owner.where.not(user_id: nil).map(&:user_id), owner_type: ['User', 'Consumer'] })
  }

  def owned_by?(owner)
    if owner.is_a?(GroupUser)
      owners.where(owner: owner).exists?
    else
      owners.only_connected.where(owner_id: owner.id).exists?
    end
  end

  def password_folder?
    self.id == PASSWORD_FOLDER_ID or self.id == BIZ_PASSWORD_FOLDER_ID
  end

  private
  def set_rank #We are only setting ranks for the documents on the first screen here. For documents inside folders, ranks are set in StandardFolderStandardDocument model
    if self.consumer_id.nil?
      if self.rank.nil? and self.category?
          highest_rank_row = StandardBaseDocument.only_system.only_category.order(rank: :desc).first
          self.rank = highest_rank_row ? (highest_rank_row.rank + 1) : 1
        end
    else
      if self.rank.nil? and self.category?
        highest_rank_row = StandardBaseDocument.where.not(consumer_id: nil).only_category.order(rank: :desc).first
        highest_rank = highest_rank_row ? highest_rank_row.rank.to_i : BUFFET_FOR_FUTURE_SYSTEM_FOLDER_RANK
        highest_rank = BUFFET_FOR_FUTURE_SYSTEM_FOLDER_RANK if highest_rank < BUFFET_FOR_FUTURE_SYSTEM_FOLDER_RANK
        self.rank = highest_rank + 1
      end
    end
  end
end
