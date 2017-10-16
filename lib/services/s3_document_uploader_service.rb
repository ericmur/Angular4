class S3DocumentUploaderService
  def initialize(document, file, opts = { })
    @document = document
    @file = file
    @delete_file = opts[:delete]
    @filename = opts[:filename]
  end

  def call
    filename = @filename ? @filename : build_filename
    encryption_key = get_decrypted_key
    S3::DataEncryption.new(encryption_key).upload(@file.path, { object_key: filename })
    File.delete(@file.path) if @delete_file
    @document.original_file_key = filename
    @document.complete_upload!
    @document.save!
  end

  private

  def get_decrypted_key
    @document.symmetric_keys.for_user_access(nil).first.decrypt_key #Get Symmetric key shared with the system to access this document
  end

  def build_filename
    [@document.id, @document.original_file_name].join('-')
  end
end
