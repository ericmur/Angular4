class DocumentUploadEmail < ActiveRecord::Base
  belongs_to :consumer, :class_name => 'User'
  belongs_to :standard_document
  belongs_to :business

  validates :consumer_id, presence: true
  validates :standard_document_id, presence: true
  validates :email, presence: true, uniqueness: true
  validates :consumer_email, presence: true
end
