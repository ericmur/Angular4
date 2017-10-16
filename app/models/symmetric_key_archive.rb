class SymmetricKeyArchive < ActiveRecord::Base
  validates :document_id, :symmetric_key_created_at, :presence => true
end
