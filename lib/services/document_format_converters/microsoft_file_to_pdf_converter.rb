module DocumentFormatConverters
  #This one converts word-doc, ppt and excel formats to pdf
  class MicrosoftFileToPdfConverter < BaseDocumentConverter

    def initialize(options = {})
      @file = options[:file]
      @document = options[:document]
      @temp_folder_location = generate_temp_folder_path("ms_to_pdf")
    end

    def convert
      if @document
        @file = download_document_file
        tmp_pdf_file = convert_process
        upload_and_update_document(tmp_pdf_file)
        create_and_upload_pages
        remove_tmp_dir_and_file(@file)
      else
        convert_process
      end
    end

    private

    def convertion_processor
      case RbConfig::CONFIG['host_os']
      when /darwin|mac os/
        'soffice'
      when /linux/
        'libreoffice'
      else
        raise Error::WebDriverError, "unknown os: #{host_os.inspect}"
      end
    end

    def convert_process
      cmd = "#{convertion_processor} --headless --convert-to pdf '#{@file.path}' --outdir #{@temp_folder_location}"
      status = system(cmd)

      filename_extension = File.extname(@file.path)
      filename_without_extension = File.basename(@file.path, filename_extension)
      raise "Image conversion failed for file #{@file.path}. Exit Status: #{$?}. Command: #{cmd}" unless status
      return File.new(File.join(@temp_folder_location, filename_without_extension + '.pdf'), 'r')
    end

  end
end
