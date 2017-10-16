class UserDocumentJson
  include Mongoid::Document

  field :user_id, type: Integer
  field :version, type: Integer, default: 0
  field :document_json, type: String

  validates :user_id, presence: true
  validates :version, presence: true, uniqueness: { scope: [:user_id] }
  validates :document_json, presence: true

  index({ user_id: 1, version: 1 }, { unique: true })
end