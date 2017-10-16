require 'active_support/concern'

module StorageCalculateable
  extend ActiveSupport::Concern

  included do
    validates :source, inclusion: { in: [CloudService::DROPBOX, CloudService::GOOGLE_DRIVE, CloudService::ONE_DRIVE, CloudService::EVERNOTE, CloudService::BOX] + %w(Photos Camera) + [User::SERVICE_PROVIDER_SOURCE, Email::SOURCE, Document::THIRD_PARTY_SOURCE, Fax::SOURCE] + Chat::SOURCE.values }, :allow_nil => true

    scope :document_storage, -> { where(source: [CloudService::DROPBOX, CloudService::GOOGLE_DRIVE, User::SERVICE_PROVIDER_SOURCE, Email::SOURCE, Document::THIRD_PARTY_SOURCE, Fax::SOURCE] + Chat::SOURCE.values) }
    scope :non_document_storage, -> { where(source: %w(Photos Camera)) }
  end

  def update_storage_size_from_s3
    raise "IMPLEMENT THIS METHODS ON INCLUDING CLASS"
  end

  # This method will be called from FetchS3ObjectLengthJob
  def perform_update_storage_size_from_s3
    raise "IMPLEMENT THIS METHODS ON INCLUDING CLASS"
  end

  # TODO : try to find better way to do this
  def fetch_object_size(object_key)
    total_size = 0
    bucket = Aws::S3::Bucket.new(ENV['DEFAULT_BUCKET'])

    objects = bucket.objects({
      max_keys: 1,
      prefix: object_key
    })

    objects.each do |o|
      total_size += o.size
    end

    total_size
  end

  def recalculate_storage_counter_later
    RecalculateStorageCounterJob.perform_later(self.id)
  end

  def recalculate_storage_counter
    recalculate_page_count
    recalculate_storage_size
  end

  def recalculate_page_count
    u = nil
    page_cnt = { }
    self.document_owners.each do |doc_owner|
      if doc_owner.connected?
        u = doc_owner.owner
      else
        if doc_owner.client?
          u = nil
        else #Must be a group_user
          u = User.find(doc_owner.owner.group.owner_id)
        end
      end

      if u and page_cnt[u].nil? #A document might have many non-connected owners, hence using the cache page_cnt[u]
        page_cnt[u] = u.recalculate_page_count(page_cnt[u])
      end
    end
  end

  def recalculate_storage_size
    u = nil
    total_storage = { }
    self.document_owners.each do |doc_owner|
      if doc_owner.connected?
        u = doc_owner.owner
      else
        if doc_owner.client?
          u = nil
        else #Must be a group_user
          u = User.find(doc_owner.owner.group.owner_id)
        end
      end

      if u and total_storage[u].nil? #A document might have many non-connected owners, hence using the cache page_cnt[u]
        total_storage[u] = u.recalculate_storage_size(total_storage[u])
      end
    end
  end

end
