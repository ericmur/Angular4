class ProcessEmailFromS3Job < ActiveJob::Base
  queue_as :default

  def perform(message)
    PullEmailFromS3Service.new(message).call do |email, filename, mime_type, temp_file|
      processed = true
      ActiveRecord::Base.transaction(requires_new: true) do
        begin
          document_extension = DocumentExtensionService.new(mime_type, filename)

          if document_extension.microsoft_file?
            converter = DocumentFormatConverters::MicrosoftFileToPdfConverter.new({file: temp_file})
            temp_file = converter.convert
            process_pdf_file(email, filename, mime_type, temp_file)
          elsif document_extension.image_file?
            converter = DocumentFormatConverters::ImageFileToPdfConverter.new({file: temp_file, mime_type: mime_type})
            temp_file = converter.convert
            process_pdf_file(email, filename, mime_type, temp_file)
          elsif document_extension.pdf_file?
            path = temp_file.path
            FlattenPdfService.new(path).flatten
            temp_file = File.new(path, 'r') #Reread temp_file as path is overridden in flattenPdfService
            process_pdf_file(email, filename, mime_type, temp_file)
          else
            SlackHelper.ping({ channel: "#errors", username: "ProcessEmailFromS3Job", message: "Unsupported file format #{mime_type} forwarded via email." })
            processed = false
            # TODO: Send notification to user for unsupported file format?
          end
        rescue => e
          if e.message.match('This file requires a password for access') || e.message.match('pdf_process_Encrypt')
            ForwardedDocumentMailer.unrecoverable_error_email(email.id).deliver_later
          end
          SlackHelper.ping({ channel: "#errors", username: "ProcessEmailFromS3Job", message: e.message })
          processed = false
          raise ActiveRecord::Rollback
        end
      end
      raise "Failed processing: #{filename}" unless processed
    end
  end

  private

  def process_pdf_file(email, filename, mime_type, temp_file)
    mime_type = MIME::Types.type_for(temp_file.path).first.content_type
    doc = email.documents.build(:uploader => email.user,
                                :source => Email::SOURCE,
                                :share_with_system => true,
                                :standard_document_id => email.standard_document_id,
                                :original_file_name => filename,
                                :file_content_type => mime_type,
                                :last_modified_at => Time.now)

    if doc.standard_document && doc.standard_document.business_document?
      business = email.business
      if business != nil
        doc.add_business(email.business)
        doc.save!
      else
        if email.user.businesses.count == 1
          business = email.user.businesses.first
          doc.add_business(email.business)
          doc.save!
        else
          raise 'Failed to set business for document'
        end
      end
      business.business_partners.each do |business_partner|
        DocumentPermission.create_permissions_if_needed(doc, business_partner.user, DocumentPermission::BUSINESS_PARTNER)
        doc.share_with(by_user_id: nil, with_user_id: business_partner.user.id)
      end
      doc.generate_standard_base_document_permissions
      doc.generate_folder_settings
      doc.generate_folder_settings_for_business
      doc.generate_standard_base_document_owners_for_business
    else
      doc.document_owners.build(:owner => email.user)
      doc.save!
      doc.generate_standard_base_document_permissions
      doc.generate_folder_settings
    end

    doc.start_upload!

    doc.reload
    S3DocumentUploaderService.new(doc, temp_file, { :delete => false, :filename => File.basename(temp_file.path) }).call
    doc.update(final_file_key: doc.original_file_key)
    if doc.standard_document.present?
      begin
        #Let's try to convert after S3DocumentUploaderService completed.
        #Trigger manually here since we need to invoke notification after conversion done.
        DocumentFormatConverters::PdfToImagesConverter.new(doc).convert unless doc.final_file_key.blank?
      rescue => e
        SlackHelper.ping({ channel: "#errors", username: "PdfToImagesConverter", message: "Document: #{doc.id}. Failed to convert PDF to Images. Message: #{e.message}" })
      end

      DocumentCacheService.update_cache([:document, :folder_setting], [email.user.id])
    end

    NotifyForwardedEmailProcessedJob.perform_later(doc.id)

    #Revoke access from DocytBot now that uploading to S3 is done
    doc.revoke_sharing(:with_user_id => nil)
  end
end
