class WorkflowDocumentUpload < ActiveRecord::Base
  belongs_to :user
  belongs_to :document
  belongs_to :workflow_standard_document

  validates :user_id, :document_id, :workflow_standard_document_id, presence: true
end
