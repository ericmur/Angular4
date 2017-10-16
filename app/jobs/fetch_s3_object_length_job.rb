class FetchS3ObjectLengthJob < ActiveJob::Base
  queue_as :default

  def perform(klass, object_id)
    fetchable_object = klass.constantize.find_by_id(object_id)
    
    if fetchable_object
      fetchable_object.perform_update_storage_size_from_s3
    end
  end
end
