class DocumentCache::AliasCacheService
  include Mixins::DocumentCacheHelper

  def initialize(params={})
    @params = params
  end

  def resource
    Alias.all
  end

  def build_json
    cache_version = create_or_update_cache_version

    alias_json = continue_with_optional_logger do
      ActiveModel::ArraySerializer.new(resource,
        root: 'aliases',
        each_serializer: ::Api::Mobile::V2::AliasSerializer,
        scope: scope
      ).as_json
    end

    alias_json.merge!({ cache_version: cache_version.version })

    output_json = alias_json.to_json

    unless cache_version_exists?(ALIAS_CACHE, cache_version)
      store_json(ALIAS_CACHE, cache_version, output_json)
    end
    cleanup_old_cache(ALIAS_CACHE, cache_version)

    output_json
  end

  private

  def cache_version_resource
    DocumentCache::AliasJsonVersion.order(version: :asc)
  end

  def cache_json_resource
    DocumentCache::AliasJson.order(version: :asc)
  end

  def create_cache_version
    DocumentCache::AliasJsonVersion.create(version: 0)
  end
end