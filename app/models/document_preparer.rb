class DocumentPreparer < ActiveRecord::Base
  belongs_to :document
  belongs_to :preparer, class_name: User.name.to_s

  validates :document_id, :preparer_id, presence: true
end
