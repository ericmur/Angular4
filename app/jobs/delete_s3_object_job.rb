class DeleteS3ObjectJob < ActiveJob::Base
  queue_as :low

  def perform(s3_object_key)
    S3::DataEncryption.delete(s3_object_key) unless s3_object_key.blank?
  end
end
