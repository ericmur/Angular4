class AddGroupRankToDocuments < ActiveRecord::Migration
  def change
    add_column :documents, :group_rank, :integer, default: 0
  end
end
