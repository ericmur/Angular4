class WorkflowStandardDocument < ActiveRecord::Base
  belongs_to :ownerable, polymorphic: true
  belongs_to :standard_document
  has_many   :workflow_document_uploads, dependent: :destroy

  validates :standard_document_id, uniqueness: { scope: [:ownerable_id, :ownerable_type] }
end
