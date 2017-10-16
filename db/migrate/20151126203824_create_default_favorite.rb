class CreateDefaultFavorite < ActiveRecord::Migration
  def change
    create_table :default_favorites do |t|
      t.integer :standard_document_id
    end
  end
end
