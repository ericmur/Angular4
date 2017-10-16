class DocumentCache::UserFolderSettingJson
  include Mongoid::Document
  include DocumentCacheMixins

  field :user_id, type: Integer
  field :version, type: Integer, default: 0
  field :data, type: String

  validates :user_id, presence: true
  validates :version, presence: true, uniqueness: { scope: [:user_id] }
  validates :data, presence: true
end