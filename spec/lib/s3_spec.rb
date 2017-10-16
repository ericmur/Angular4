require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'
require 's3'

describe S3 do
  describe S3::DataEncryption do
    
    def part_size_suffix
      case RbConfig::CONFIG['host_os']
      when /darwin|mac os/
        'mb'
      when /linux/
        'M'
      else
        raise Error::WebDriverError, "unknown os: #{host_os.inspect}"
      end
    end

    def expected_url_for(path)
      "https:\/\/#{ENV['DEFAULT_BUCKET']}.s3.amazonaws.com\/#{File.basename(path).gsub('/','\/')}"
    end

    before(:each) do
      FileUtils.mkdir_p TEST_WORKDIR

      @de_1 = S3::DataEncryption.new
      @de_2 = S3::DataEncryption.new(@de_1.encryption_key)

      stub_const("S3::DataEncryption::DEFAULT_PART_SIZE", "5#{part_size_suffix}")
    end

    after(:each) do
      FileUtils.rmdir TEST_WORKDIR
    end

    it 'must successfully set encryption algorithm and create key, md5 digest for the key' do
      data_encryption = S3::DataEncryption.new
      expect(data_encryption.encryption_algorithm).to be_present
      expect(data_encryption.key_md5_digest).to be_present
      expect(data_encryption.encryption_key).to be_present
    end

    it 'must successfully load key when provided and set encryption algorithm and create md5 digest for the key' do
      md5 = Encryption::MD5Digest.new

      expect(@de_1.encryption_key).to eq(@de_2.encryption_key)
      expect(@de_1.encryption_algorithm).to eq(@de_2.encryption_algorithm)
      expect(@de_1.key_md5_digest).to eq(@de_2.key_md5_digest)

      encryption_key_base_64 = Base64.encode64(@de_1.encryption_key)
      key_md5_digest = md5.digest_base64(@de_1.encryption_key)

      expect(@de_2.encryption_key_base_64).to eq(encryption_key_base_64)
      expect(@de_2.key_md5_digest).to eq(key_md5_digest)
    end

    it 'must successfully upload and download to s3 with encryption' do
      upload_file_path = "#{TEST_WORKDIR}/upload#{Time.now.to_i}.txt"
      download_file_path = "#{TEST_WORKDIR}/upload#{Time.now.to_i}.txt"

      generate_sample_file(upload_file_path)

      response = @de_1.upload(upload_file_path)

      expected_url = expected_url_for(upload_file_path)

      @de_2.download(File.basename(upload_file_path), download_file_path)

      upload_file_content = File.open(upload_file_path, "rb").read
      download_file_content = File.open(download_file_path, "rb").read

      expect(upload_file_content).to eq(download_file_content)
    end

    it 'must successfully set encryption algorithm and create key, md5 digest for the key' do
      data_encryption = S3::DataEncryption.new
      expect(data_encryption.encryption_algorithm).to be_present
      expect(data_encryption.key_md5_digest).to be_present
      expect(data_encryption.encryption_key).to be_present
    end

    it 'must successfully load key when provided and set encryption algorithm and create md5 digest for the key' do
      md5 = Encryption::MD5Digest.new

      expect(@de_1.encryption_key).to eq(@de_2.encryption_key)
      expect(@de_1.encryption_algorithm).to eq(@de_2.encryption_algorithm)
      expect(@de_1.key_md5_digest).to eq(@de_2.key_md5_digest)

      encryption_key_base_64 = Base64.encode64(@de_1.encryption_key)
      key_md5_digest = md5.digest_base64(@de_1.encryption_key)

      expect(@de_2.encryption_key_base_64).to eq(encryption_key_base_64)
      expect(@de_2.key_md5_digest).to eq(key_md5_digest)
    end

    it 'must successfully upload and download to s3 with encryption' do
      upload_file_path = "#{TEST_WORKDIR}/upload#{Time.now.to_i}.txt"
      download_file_path = "#{TEST_WORKDIR}/upload#{Time.now.to_i}.txt"

      generate_sample_file(upload_file_path)

      response = @de_1.upload(upload_file_path)

      @de_2.download(File.basename(upload_file_path), download_file_path)

      upload_file_content = File.open(upload_file_path, "rb").read
      download_file_content = File.open(download_file_path, "rb").read

      expect(upload_file_content).to eq(download_file_content)
    end

    it 'must be able to set custom part size' do
      upload_file_path = "#{TEST_WORKDIR}/upload#{Time.now.to_i}.txt"
      generate_sample_file(upload_file_path, 1048576, 10)

      response = @de_1.upload(upload_file_path, { part_size: "10#{part_size_suffix}" })

      expect(@de_1.upload_parts.size).to eq(1)
    end

    it 'must be able to split upload to DEFAULT_PART_SIZE when uploaded size is greater' do
      upload_file_path = "#{TEST_WORKDIR}/upload#{Time.now.to_i}.txt"
      generate_sample_file(upload_file_path, 1048576, 10)

      response = @de_1.upload(upload_file_path)

      expect(@de_1.upload_parts.size).to eq(2)

      download_response = @de_1.download(File.basename(upload_file_path), nil)
      expect(download_response[:body]).to be_present
    end

    it 'must be able to return pre-signed url for uploaded file' do
      upload_file_path = "#{TEST_WORKDIR}/upload#{Time.now.to_i}.txt"

      generate_sample_file(upload_file_path)

      response = @de_1.upload(upload_file_path)

      pre_signed_url = @de_1.presigned_url(File.basename(upload_file_path))

      expect(pre_signed_url).to be_present
    end

  end
end
