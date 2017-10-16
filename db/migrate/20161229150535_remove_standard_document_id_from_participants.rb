class RemoveStandardDocumentIdFromParticipants < ActiveRecord::Migration
  def change
    remove_column :participants, :standard_document_id
  end
end
