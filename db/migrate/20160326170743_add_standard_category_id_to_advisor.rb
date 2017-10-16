class AddStandardCategoryIdToAdvisor < ActiveRecord::Migration
  def change
    add_reference :users, :standard_category
  end
end
