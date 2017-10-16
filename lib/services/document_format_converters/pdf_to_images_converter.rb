module DocumentFormatConverters

  class PdfToImagesConverter < BaseDocumentConverter
    
    def initialize(document)
      @document      = document
      @s3_object_key = document.final_file_key
      
      @temp_folder_location = generate_temp_folder_path('pdf_to_img')
      @temp_pdf_location    = "#{@temp_folder_location}#{@s3_object_key}"
    end
    
    def convert
      FileUtils.mkdir_p(@temp_folder_location)
      raise "Document #{@document.id} does not have a pdf extension" unless s3_object_have_pdf_extensions?
      
      download_from_s3(@temp_pdf_location, @s3_object_key)
      raise "Document #{@document.id} is not a pdf based on magic bytes" unless file_is_pdf?
      pdf = Grim.reap(@temp_pdf_location)
      
      page_entity = nil
      pdf.each_with_index do |page, index|
        page_num     = index+1
        path_to_page = "#{@temp_folder_location}page-#{page_num}.jpg"
        
        page.save(path_to_page, :alpha => 'flatten') 
        page_md5_digest = md5_digest(path_to_page)
        
        page_entity = @document.pages.create(page_num: page_num, name: "", source: "ServiceProvider")
        page_entity.original_file_md5 = page_md5_digest
        page_entity.final_file_md5 = page_md5_digest
        page_entity.start_upload!
        original_page_s3_key = "Page-original-#{page_entity.id}.jpg"
        cropped_page_s3_key  = "Page-cropped-#{page_entity.id}.jpg"
        
        upload_to_s3(path_to_page, original_page_s3_key)
        upload_to_s3(path_to_page, cropped_page_s3_key)
        
        set_encryption_keys(page_entity)
        page_entity.update( original_s3_object_key: original_page_s3_key,
                            s3_object_key: cropped_page_s3_key,
                            original_file_md5: page_md5_digest,
                            final_file_md5: page_md5_digest )
        page_entity.complete_upload!
      end
      PageThumbnailConverter.new(@document, :revoke_sharing => false).convert
      
      page_entity.document.enqueue_create_notification_for_completed_page(@document.uploader, page_entity)
      page_entity.update_document_initial_pages_completion
      @document.complete_convertation!
      
      # revoke Docyt access if convertation succeed
      @document.revoke_sharing(with_user_id: nil)

      DocumentCacheService.update_cache([:document, :folder_setting], @document.consumer_ids_for_owners)
    ensure
      FileUtils.remove_dir(@temp_folder_location)
    end
    
    private
    
    def s3_object_have_pdf_extensions?
      @s3_object_key.ends_with?('.pdf')
    end
    
    def file_is_pdf?
      #Sometimes mime type for pdf comes as octet-stream, then we look at pdf extension
      Magic.guess_file_mime_type(@temp_pdf_location) == 'application/pdf' or (Magic.guess_file_mime_type(@temp_pdf_location) == 'application/octet-stream' and File.extname(@temp_pdf_location).downcase == ".pdf")
    end
    
    def md5_digest(path_to_file)
      ::Encryption::MD5Digest.new.file_hexdigest(path_to_file)
    end
    
    def set_encryption_keys(page)
      symmetric_key = page.document.symmetric_keys.for_user_access(nil).first
      page.encryption_key = symmetric_key.decrypt_key
    end
  end

end
