class AddSuggestedAtToDocument < ActiveRecord::Migration
  def change
    add_column :documents, :suggested_at, :datetime
  end
end
