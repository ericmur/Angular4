class CloudServicePath < ActiveRecord::Base
  belongs_to :consumer, class_name: 'User'
  belongs_to :cloud_service_authorization
  has_many   :documents, :dependent => :nullify #If documents have been categorized and approved, we cannot delete them
  has_many   :documents_to_auto_categorize, -> { where(:suggested_standard_document_id => nil) }, :class_name => 'Document'
  has_many   :documents_auto_categorized, -> { where.not(:suggested_standard_document_id => nil).where(:standard_document_id => nil) }, :class_name => 'Document'

  validates :path, uniqueness: { scope: [:consumer_id, :cloud_service_authorization_id] }
  validates :path, presence: true
  validates :path_display_name, presence: true, :if => Proc.new { |obj| obj.cloud_service_authorization and obj.cloud_service_authorization.cloud_service.google_drive? }

  before_validation :set_path_display_name_if_needed, :on => :create

  def sync_data
    PullDocumentsByCloudServicePathJob.perform_later(id)
  end

  private

  def set_path_display_name_if_needed
    if self.cloud_service_authorization and self.cloud_service_authorization.cloud_service.dropbox? #Incase of drive path and path_display_name are different
      self.path_display_name = self.path
    end
  end
end
