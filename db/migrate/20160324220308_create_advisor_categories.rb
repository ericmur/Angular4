class CreateAdvisorCategories < ActiveRecord::Migration
  def change
    create_table :advisor_categories do |t|

      t.timestamps null: false
    end
  end
end
