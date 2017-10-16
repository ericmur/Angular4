class AddPurposeToWorkflows < ActiveRecord::Migration
  def change
    add_column :workflows, :purpose, :string
  end
end
