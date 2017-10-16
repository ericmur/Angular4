class RemoveAdvisorData < ActiveRecord::Migration
  def change
    drop_table :advisor_data
  end
end
