class CreateUserMigrations < ActiveRecord::Migration
  def change
    create_table :user_migrations do |t|
      t.boolean :img_to_pdf_conversion_done, :default => true
      t.references :user
      t.timestamps null: false
    end
  end
end
