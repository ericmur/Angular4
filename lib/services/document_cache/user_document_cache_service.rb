class DocumentCache::UserDocumentCacheService
  include Mixins::DocumentCacheHelper

  def initialize(user, params, store_in_background=true)
    @user = user
    @params = params
    @store_in_background = store_in_background
  end

  def resource
    Api::Mobile::V2::DocumentsQuery.new(@user, @params).get_documents
  end

  def update_version
    create_or_update_cache_version
    if @store_in_background == true
      Resque.enqueue UserDocumentCacheUpdateJob, @user.id
    else
      build_json
    end
  end

  def build_json
    verify_user!

    cache_version = find_or_create_cache_version

    documents_json = continue_with_optional_logger do
      ActiveModel::ArraySerializer.new(resource,
        root: 'documents',
        each_serializer: Api::Mobile::V2::DocumentSerializer,
        scope: scope
      ).as_json
    end

    documents_json.merge!({ cache_version: cache_version.version })

    output_json = documents_json.to_json

    if @store_in_background == true
      Resque.enqueue UserDocumentCacheUpdateJob, @user.id
    else
      # Version number was updated before `UserDocumentCacheUpdateJob` enqueued.
      # If job falied, we should skip creating `DocumentCache::UserDocumentJson`.
      # To update the version again, we need to run `DocumentCacheService.update_cache`, instead of re-run `UserDocumentCacheUpdateJob`
      unless cache_version_exists?(USER_DOCUMENT_CACHE, cache_version)
        store_json(USER_DOCUMENT_CACHE, cache_version, output_json)
      end
      cleanup_old_cache(USER_DOCUMENT_CACHE, cache_version)
    end

    output_json
  end

  def cache_version_resource
    DocumentCache::UserDocumentJsonVersion.where(user_id: @user.id).order(version: :asc)
  end

  def cache_json_resource
    DocumentCache::UserDocumentJson.where(user_id: @user.id).order(version: :asc)
  end

  def create_cache_version
    DocumentCache::UserDocumentJsonVersion.create(user_id: @user.id, version: 0)
  end
end