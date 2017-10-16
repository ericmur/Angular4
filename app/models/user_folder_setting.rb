class UserFolderSetting < ActiveRecord::Base
  belongs_to :user
  belongs_to :folder_owner, polymorphic: true
  belongs_to :standard_base_document

  scope :for_folder, -> (folder_id) { where(standard_base_document_id: folder_id) }
  scope :for_standard_base_document, -> (standard_base_document_id) { where(standard_base_document_id: standard_base_document_id) }
  scope :for_folder_owner, -> (owner) { where(folder_owner: owner) }
  scope :hidden, -> { where(displayed: false) }
  scope :displayed, -> { where(displayed: true) }

  validates :user_id, presence: true
  validates :folder_owner_id, presence: true
  validates :standard_base_document_id, presence: true
  validates :standard_base_document_id, uniqueness: { scope: [:user_id, :folder_owner_id, :folder_owner_type], message: 'folder already hidden' }

  # This is used for grouping for serializer to return list of hidden folders as hash
  # folder_settings => {
  #   'consumer-1' => [standard_base_document_id, 1, 2, 3, 4, 5]
  #   'group-user-17' => [6, 7, 4, 1, 5]
  # }
  # Resulted hash will be used on client side to lookup which folder is hidden
  def folder_owner_identifier
    [folder_owner_type.underscore.dasherize, folder_owner_id].join('-')
  end

  # This is now used for User/Consumer only
  # For group user check GroupUser#generate_folder_settings
  def self.setup_folder_setting_for_user(user)
    folders = StandardBaseDocumentAccountType.where(:consumer_account_type_id => ConsumerAccountType::INDIVIDUAL)
    std_folders_not_allowed = StandardFolder.only_system.only_category.where.not(:id => folders.map(&:standard_folder_id))
    
    displayed_documents = Document.select('standard_document_id').where("standard_document_id is not null").joins(:document_owners).where(document_owners: { owner_id: user.id, owner_type: %w{User Consumer} })
    base_doc_ids = displayed_documents.map{|d| d.standard_document.standard_folder_standard_documents.map(&:standard_folder_id) }.flatten.uniq
    max_base_doc_id = StandardBaseDocument.where(consumer_id: nil).maximum(:id)
    user.user_folder_settings.where(folder_owner: user).where('standard_base_document_id <= ? AND standard_base_document_id NOT IN (?)', max_base_doc_id, base_doc_ids).destroy_all
    
    (folders + std_folders_not_allowed).each do |folder|
      std_folder_id = folder.is_a?(StandardFolder) ? folder.id : folder.standard_folder_id
      user_folder_setting = user.user_folder_settings.where(:standard_base_document_id => std_folder_id, :folder_owner => user).first
      folder_show = folder.is_a?(StandardFolder) ? false : folder.show
      if user_folder_setting.nil?
        user_folder_setting = user.user_folder_settings.build(:standard_base_document_id => std_folder_id, :folder_owner => user, :displayed => folder_show)
      else
        user_folder_setting.displayed = folder_show
      end
      user_folder_setting.save!
    end
  end
end
