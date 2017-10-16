class AddRejectedAtToDocuments < ActiveRecord::Migration
  def change
    add_column :documents, :rejected_at, :datetime
  end
end
