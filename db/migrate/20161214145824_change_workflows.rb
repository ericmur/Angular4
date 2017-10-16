class ChangeWorkflows < ActiveRecord::Migration
  def change
    add_column :workflows, :end_date, :datetime
    add_column :workflows, :status, :string

    rename_column :workflows, :advisor_id, :admin_id

    remove_column :workflows, :kind
  end
end
