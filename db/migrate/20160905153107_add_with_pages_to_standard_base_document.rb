class AddWithPagesToStandardBaseDocument < ActiveRecord::Migration
  def change
    add_column :standard_base_documents, :with_pages, :boolean, :default => true
  end
end
