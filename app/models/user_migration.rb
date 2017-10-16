class UserMigration < ActiveRecord::Base
  belongs_to :user

  def migrate_to_create_pdfs_for_documents
    return if self.img_to_pdf_conversion_done
    self.user.document_ownerships.map(&:document).each do |document|
      if document.all_pages_uploaded? and document.symmetric_keys.exists?
        document.share_with(:by_user_id => self.user_id, :with_user_id => nil)
        Resque.enqueue ConvertDocumentPagesToPdfJob, document.id #Generates the pdf as well as first page thumbnail
      end
    end
    self.img_to_pdf_conversion_done = true
    self.save!
  end

  def migrate_to_create_first_page_thumbnail
    return if self.first_page_thumbnail_migration_done
    Api::Mobile::V2::DocumentsQuery.new(self.user, {}).get_documents.find_each do |document|
      next unless document.symmetric_keys.for_user_access(self.user.id).exists?
      if document.is_owned_by?(self.user) || document.consumer_id == self.user_id
        if document.first_page_thumbnail or (document.all_pages_uploaded? && document.pages.exists?) #Overwrite last thumbnail if needed
          document.first_page_thumbnail = nil
          document.save!
        
          document.share_with(with_user_id: nil, by_user_id: user_id)
          Resque.enqueue GenerateFirstPageThumbnailJob, document.id
        end
      end
    end
    self.first_page_thumbnail_migration_done = true
    self.save!
  end
end
