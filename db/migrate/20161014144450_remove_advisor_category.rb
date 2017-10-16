class RemoveAdvisorCategory < ActiveRecord::Migration
  def change
    drop_table :advisor_categories
  end
end
