require 'encryption'
require 'mime-types'

module S3
  class DataEncryption
    case RbConfig::CONFIG['host_os']
    when /darwin|mac os/
      DEFAULT_PART_SIZE = '100mb'
    when /linux/
      DEFAULT_PART_SIZE = '100M'
    else
      raise Error::WebDriverError, "unknown os: #{host_os.inspect}"
    end

    attr_accessor :encryption_algorithm, :encryption_key, :encryption_iv
    attr_accessor :encryption_key_base_64, :key_md5_digest
    attr_accessor :upload_parts, :multipart_upload

    def initialize(encryptor_key=nil, opts={})
      @aes_encryptor = Encryption::Aes.new
      self.encryption_algorithm = 'AES256'

      self.encryption_iv = @aes_encryptor.iv

      self.encryption_key = encryptor_key || @aes_encryptor.key
      self.encryption_key_base_64 = Base64.encode64(self.encryption_key)

      @md5 = Encryption::MD5Digest.new
      self.key_md5_digest = @md5.digest_base64(self.encryption_key)

      @s3_client = ::Aws::S3::Client.new
      @default_bucket = opts[:bucket] || ENV['DEFAULT_BUCKET']

      self.upload_parts = []
    end

    def self.delete(key, opts={ })
      bucket = opts[:bucket] || ENV['DEFAULT_BUCKET']
      self.delete_object(bucket, key)
    end

    #AWS SSE-C Multipart Upload
    def upload(path, opts={})
      bucket = opts[:bucket] || @default_bucket
      part_size = opts[:part_size] || DEFAULT_PART_SIZE

      object_to_upload = path
      object_key = object_to_upload[1..-1]

      key = opts[:object_key] || File.basename(object_to_upload)
      result = nil
      parts = {}
      tags = []

      Dir.mktmpdir do |workdir|
        `split -b #{part_size} -a 3 "#{object_to_upload}" #{workdir}/`

        Dir.entries("#{workdir}/").each do |file|
          next if file =~ /^\.\.$/
          next if file =~ /^\.$/

          full_path = "#{workdir}/#{file}"
          parts[full_path] = @md5.file_digest_base64(full_path)
        end

        sorted_parts = parts.sort_by do |d, m|
          d.split('/').last.to_i
        end

        self.multipart_upload = create_multipart_upload(bucket, key)

        sorted_parts.each_with_index do |entry, idx|
          part_number = idx + 1
          file_content = File.open(entry[0]).read
          part_upload = upload_part(bucket, key, file_content, part_number, entry[1])
          tags << { etag: part_upload.etag.to_s, part_number: part_number }
          self.upload_parts << part_upload
        end

        result = complete_multipart_upload(bucket, key, tags)
      end

      result
    end

    #AWS SSE-C GET
    def download(key, target_path, opts={})
      bucket = opts[:bucket] || @default_bucket
      get_object(bucket, key, target_path)
    end

    # This method was not fully get the content because it's encrypted
    # but placing this method so we can lookup in the future
    def presigned_url(key)
      bucket = ENV['DEFAULT_BUCKET']
      signer = Aws::S3::Presigner.new(client: @s3_client)
      signer.presigned_url(:get_object, bucket: bucket, key: key)
    end

    private

    def get_object(bucket, key, target_path)
      @s3_client.get_object(response_target: target_path,
                            bucket: bucket,
                            key: key,
                            sse_customer_algorithm: self.encryption_algorithm,
                            sse_customer_key: self.encryption_key,
                            sse_customer_key_md5: self.key_md5_digest)
    end

    def self.delete_object(bucket, key)
      ::Aws::S3::Client.new.delete_object(bucket: bucket,
                                          key: key)
    end

    def create_multipart_upload(bucket, key)
      @s3_client.create_multipart_upload(bucket: bucket,
                                         key: key,
                                         sse_customer_algorithm: self.encryption_algorithm,
                                         sse_customer_key: self.encryption_key,
                                         sse_customer_key_md5: self.key_md5_digest)
    end

    def upload_part(bucket, key, body, part_number, content_md5)
      @s3_client.upload_part(body: body,
                             bucket: bucket,
                             key: key,
                             upload_id: self.multipart_upload.upload_id,
                             part_number: part_number,
                             content_md5: content_md5,
                             sse_customer_algorithm: self.encryption_algorithm,
                             sse_customer_key: self.encryption_key,
                             sse_customer_key_md5: self.key_md5_digest)
    end

    def complete_multipart_upload(bucket, key, tags)
      @s3_client.complete_multipart_upload(bucket: bucket,
                                           key: key,
                                           upload_id: self.multipart_upload.upload_id,
                                           multipart_upload: {
                                             parts: tags,
                                           })
    end

  end
end
