class AddInitialPagesCompletedToDocuments < ActiveRecord::Migration
  def change
    add_column :documents, :initial_pages_completed, :boolean, default: false
  end
end
