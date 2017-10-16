require 'open3'
require 'slack_helper'

module DocumentFormatConverters
  class PageThumbnailConverter < BaseDocumentConverter
    def initialize(document, opts = { :revoke_sharing => true })
      @document = document
      @revoke_sharing = opts[:revoke_sharing] ? true : false
      @temp_folder_location = generate_temp_folder_path('img_to_thumb')
    end

    def revoke_docytbot_if_needed
      if @revoke_sharing #If this converter is called directly (not via a resque job), then it might be necessary to not revoke access to DocytBot yet because the calling process might need to use the access still. This field is used by the calling process to notify PageThumbnailConverter to not revoke access
        unless @document.needs_sharing_with_docytbot?
          @document.revoke_sharing(with_user_id: nil)
        end
      end
    end

    def convert
      FileUtils.mkdir_p(@temp_folder_location)
      unless @document.all_pages_uploaded? and @document.pages.exists?
        return
      end

      old_thumb_filename = nil
      if @document.first_page_thumbnail.present?
        old_thumb_filename = @document.first_page_thumbnail
      end

      page = @document.pages.order(page_num: :asc).first

      thumb_filename = page.s3_object_key.gsub('cropped','thumbnail')
      unless old_thumb_filename != thumb_filename
        revoke_docytbot_if_needed
        return
      end

      path_to_page = "#{@temp_folder_location}#{page.s3_object_key}"
      download_from_s3(path_to_page, page.s3_object_key)

      is_valid_type = Magic.guess_file_mime_type(path_to_page).starts_with?('image/')
      if !is_valid_type
        SlackHelper.ping({ channel: "#errors", username: "PageThumbnailConverter", message: "Page #{page.id} contains file with invalid mime-type!" })
      end

      if @document.first_page_thumbnail.present?
        old_thumb_filename = @document.first_page_thumbnail
      end

      temp_image_location = "#{@temp_folder_location}#{thumb_filename}"

      cmd = "convert -resize 640x480 -quality 50 \"#{path_to_page}\" \"#{temp_image_location}\""
      stdout, stdeerr, status = Open3.capture3(cmd)
      unless status.exitstatus == 0
        if stdeerr.present?
          raise stdeerr.split("\n").first.strip
        elsif stdout.present?
          raise stdout.split("\n").first.strip
        else
          raise "Failed to convert page first page thumbnail for document: #{@document.id}"
        end
      end

      upload_to_s3(temp_image_location, thumb_filename)
      @document.update(first_page_thumbnail: thumb_filename)

      revoke_docytbot_if_needed

      if old_thumb_filename.present? && old_thumb_filename != thumb_filename
        DeleteS3ObjectJob.perform_later(old_thumb_filename)
      end
    ensure
      FileUtils.remove_dir(@temp_folder_location)
    end
  end
end
