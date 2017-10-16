class AddFieldsToAdvisorCategories < ActiveRecord::Migration
  def change
    add_reference :advisor_categories, :advisor
    add_reference :advisor_categories, :category
  end
end
