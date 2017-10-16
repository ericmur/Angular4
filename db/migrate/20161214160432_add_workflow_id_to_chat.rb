class AddWorkflowIdToChat < ActiveRecord::Migration
  def change
    add_column :chats, :workflow_id, :integer, index: true
  end
end
