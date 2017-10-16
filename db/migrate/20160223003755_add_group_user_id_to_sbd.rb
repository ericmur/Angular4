class AddGroupUserIdToSbd < ActiveRecord::Migration
  def change
    add_reference :standard_base_documents, :group_user, :index => true
  end
end
