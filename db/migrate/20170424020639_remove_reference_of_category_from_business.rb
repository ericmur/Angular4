class RemoveReferenceOfCategoryFromBusiness < ActiveRecord::Migration
  def change
    remove_foreign_key :businesses, column: :standard_category_id
  end
end
