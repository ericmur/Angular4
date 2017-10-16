#Specifies if we are showing a folder or not in the default Folders list that we initially create for user. UserFolderSettings for a user is initialized from this.
#Also specifies which are the default document types to show inside a specific folder.
class StandardBaseDocumentAccountType < ActiveRecord::Base
  self.table_name = "consumer_folder_account_types"
  belongs_to :standard_base_document, :foreign_key => 'standard_folder_id'
  belongs_to :consumer_account_type

  scope :only_system_for_consumer_account_type, -> (consumer_account_type_id) { joins(:standard_base_document).where(standard_base_documents: { consumer_id: nil }).where(consumer_account_type_id: consumer_account_type_id) }
  scope :for_consumer_account_type, -> (consumer_account_type_id) { where(consumer_account_type_id: consumer_account_type_id) }
  scope :for_standard_folders, -> { joins(:standard_base_document).where(standard_base_documents: { type: StandardFolder.name }) }
  scope :for_standard_documents, -> { joins(:standard_base_document).where(standard_base_documents: { type: StandardDocument.name }) }
end
