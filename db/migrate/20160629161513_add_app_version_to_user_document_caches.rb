class AddAppVersionToUserDocumentCaches < ActiveRecord::Migration
  def change
    add_column :user_document_caches, :mobile_app_version, :string
  end
end
