module DocumentFormatConverters

  class BaseDocumentConverter

    def convert
      raise "Implement in the subclass"
    end

    private

    def generate_temp_folder_path(folder_name)
      timestamp = Time.now.strftime('%Y%m%d%H%M%S')
      if @document
        "./tmp/#{folder_name}/#{timestamp}-#{@document.id}/"
      else
        "./tmp/#{folder_name}/#{timestamp}/"
      end
    end

    def download_from_s3(download_path, s3_object_key)
      encryption_key = get_decrypted_key
      S3::DataEncryption.new(encryption_key).download(s3_object_key, download_path)
    end

    def upload_to_s3(path_to_file, s3_object_key)
      encryption_key = get_decrypted_key
      S3::DataEncryption.new(encryption_key).upload(path_to_file, { object_key: s3_object_key })
    end

    def get_decrypted_key
      @key ||= @document.symmetric_keys.for_user_access(nil).first.decrypt_key
    end

    def download_document_file
      path_to_document = "#{Rails.root}/tmp/#{@document.original_file_key}"
      download_from_s3(path_to_document, @document.original_file_key)

      File.new(path_to_document)
    end

    def upload_and_update_document(tmp_pdf_file)
      @document.start_upload
      pdf_file_name = File.basename(tmp_pdf_file)
      upload_to_s3(tmp_pdf_file.path, pdf_file_name)
      @document.complete_upload
      @document.update(final_file_key: pdf_file_name, state: 'converting')
    end

    def create_and_upload_pages
      DocumentFormatConverters::PdfToImagesConverter.new(@document).convert
    end

    def remove_tmp_dir_and_file(file)
      File.delete(file.path)
      FileUtils.rm_rf(@temp_folder_location)
    end

  end

end
