class DocumentCache::SystemStandardDocumentCacheService
  include Mixins::DocumentCacheHelper

  def initialize(params={})
    @params = params
  end

  def resource
    StandardBaseDocument.where(category: [false, nil]).only_system.order(rank: :asc)
  end

  def build_json
    cache_version = create_or_update_cache_version

    standard_documents_json = continue_with_optional_logger do
      ActiveModel::ArraySerializer.new(resource,
        root: 'standard_base_documents',
        each_serializer: Api::Mobile::V2::StandardBaseDocumentSerializer,
        scope: scope
      ).as_json
    end

    standard_documents_json.merge!({ cache_version: cache_version.version })

    output_json = standard_documents_json.to_json

    unless cache_version_exists?(SYSTEM_STANDARD_DOCUMENT_CACHE, cache_version)
      store_json(SYSTEM_STANDARD_DOCUMENT_CACHE, cache_version, output_json)
    end
    cleanup_old_cache(SYSTEM_STANDARD_DOCUMENT_CACHE, cache_version)

    output_json
  end

  private

  def cache_version_resource
    DocumentCache::SystemStandardDocumentJsonVersion.order(version: :asc)
  end

  def cache_json_resource
    DocumentCache::SystemStandardDocumentJson.order(version: :asc)
  end

  def create_cache_version
    DocumentCache::SystemStandardDocumentJsonVersion.create(version: 0)
  end
end