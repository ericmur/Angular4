class CreateAdvisorDefaultFolders < ActiveRecord::Migration
  def change
    create_table :advisor_default_folders do |t|
      t.references    :standard_category
      t.references    :standard_folder
      t.timestamps null: false
    end
  end
end
