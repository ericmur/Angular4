module DocumentFormatConverters
  class ImageFileToPdfConverter < BaseDocumentConverter

    def initialize(options = {})
      @file = options[:file]

      @document  = options[:document]
      @mime_type = options[:mime_type] || @document.file_content_type

      @output_filename      = "page-#{Time.now.to_i}.pdf"
      @temp_folder_location = generate_temp_folder_path('image_file_to_pdf')
      @temp_output_filename = "#{@temp_folder_location}#{@output_filename}"
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

    def interchange_image_file?
      ['gif', 'png'].each do |ext|
        if MIME::Types.type_for(ext).map(&:content_type).include?(@mime_type)
          return true
        end
      end
      false
    end

    def convert_process
      FileUtils.mkdir_p(@temp_folder_location)

      if interchange_image_file?
        cmd = "convert \"#{@file.path}[0]\" -layers flatten #{@temp_output_filename}"
      else
        cmd = "convert \"#{@file.path}\" -layers flatten #{@temp_output_filename}"
      end
      status = system(cmd)

      raise "Image conversion failed for file #{@file.path}. Exit Status: #{$?}. Command: #{cmd}" unless status

      return File.new(@temp_output_filename, 'r')
    end

  end
end
