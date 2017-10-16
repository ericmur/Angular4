class AddFirstPageThumbnailMigrationDoneToUserMigrations < ActiveRecord::Migration
  def change
    add_column :user_migrations, :first_page_thumbnail_migration_done, :boolean, default: false
  end
end
