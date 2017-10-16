class AddFirstPageThumbnailToDocuments < ActiveRecord::Migration
  def change
    add_column :documents, :first_page_thumbnail, :string
  end
end
