class StandardDocumentFieldOwner < ActiveRecord::Base
  belongs_to :standard_document_field
  belongs_to :owner, :polymorphic => true
end
