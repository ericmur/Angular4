class DocumentCache::AliasJson
  include Mongoid::Document
  include DocumentCacheMixins

  field :data, type: String
  field :version, type: Integer, default: 0

  validates :data, presence: true
  validates :version, presence: true, uniqueness: true
end