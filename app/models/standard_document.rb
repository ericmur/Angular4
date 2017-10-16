#Do not add :dependent => nullify to this model for its associations. This is so we can create the relationship with standard_document (for the associations) again when categories are restructured. During restructuring we call StandardBaseDocument.load which re-creates the categories structure
class StandardDocument < StandardBaseDocument
  BUSINESS_RECEIPT_ID = 256
  PERSONAL_RECEIPT_ID = 169
  
  has_many :documents, :foreign_key => 'standard_document_id' #, :dependent => :nullify - do not dependent nullify for the reason above
  has_one :first_time_standard_document, :dependent => :destroy #These are the documents that are shown for upload on mobile device when user first signs up
  has_many :suggested_documents, :foreign_key => 'suggested_standard_document_id' #These are all the documents that were suggested to be of this type of StandardDocument by DocytBot's auto-categorization module
  has_many :standard_document_fields, -> { where("document_id is null") }, :dependent => :destroy, :class_name => 'BaseDocumentField'
  has_many :default_favorites, :dependent => :destroy
  belongs_to :dimension
  has_many :aliases, :dependent => :destroy, :as => :aliasable

  def standard_folder
    self.standard_folder_standard_documents.first.standard_folder if standard_folder_standard_documents.any?
  end

  def document_uploaders
    User.where(id: documents.map(&:consumer_id))
  end
end
