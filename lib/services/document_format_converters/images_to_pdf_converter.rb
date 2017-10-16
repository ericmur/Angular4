module DocumentFormatConverters

  class ImagesToPdfConverter < BaseDocumentConverter

    def initialize(document)
      @document = document

      @pdf_filename         = "document-#{@document.id}.pdf"
      @temp_folder_location = generate_temp_folder_path('img_to_pdf')
      @temp_pdf_location    = "#{@temp_folder_location}#{@pdf_filename}"
    end

    def convert
      FileUtils.mkdir_p(@temp_folder_location)
      if (first_page = @document.pages.order("page_num ASC").first) and first_page.uploaded?
        PageThumbnailConverter.new(@document, :revoke_sharing => false).convert
      end

      unless @document.all_pages_uploaded? and @document.pages.exists?
        return
      end

      absolute_pages_paths = []

      @document.pages.each do |page|
        # This is rare case. But there are possibility when Page is reuploaded while Job already enqueued
        raise "Failed to convert PDF. Page #{page.id} is currently uploading" if page.uploading? || page.s3_object_key.blank?

        path_to_page = "#{@temp_folder_location}#{page.s3_object_key}"
        absolute_pages_paths << "#{Rails.root}#{path_to_page[1..-1]}"
        download_from_s3(path_to_page, page.s3_object_key)
        is_valid_type = Magic.guess_file_mime_type(path_to_page).starts_with?('image/')

        raise "Page #{page.id} contains file with invalid mime-type!" unless is_valid_type
      end

      #More info about auto-orient option here: http://unix.stackexchange.com/questions/267637/stop-imagemagick-from-rotating-image-on-append
      cmd = "convert -auto-orient -limit memory 1GiB -limit map 2GiB #{absolute_pages_paths.join(' ')} -quality 50 -adjoin #{Rails.root}#{@temp_pdf_location[1..-1]}"
      status = system(cmd)
      raise "Image conversion failed for document with id #{@document.id}. Exit Status: #{$?}. Command: #{cmd}" unless status

      @document.state = "uploading" #start_upload! will require state to be pending and also original_file_key to be set. Since neither of that is set here, we will just set state to uploading directly here.
      upload_to_s3(@temp_pdf_location, @pdf_filename)
      @document.final_file_key = @pdf_filename
      @document.complete_upload!
      @document.save!

      # revoke Docyt access if convertation succeeded and there is no more request to convert for this document that is enqueued.
      # There could still be a corner case where if another job got scheduled right at the time we are performing this check, then we might revoke the sharing early while there is another job in queue.
      unless @document.needs_sharing_with_docytbot?
        @document.revoke_sharing(with_user_id: nil)
      end
    ensure
      FileUtils.remove_dir(@temp_folder_location)
    end

  end

end
