class DocumentCache::SystemStandardFolderJsonVersion
  include Mongoid::Document
  include DocumentCacheMixins

  field :version, type: Integer, default: 0
  validates :version, presence: true, uniqueness: true
end

