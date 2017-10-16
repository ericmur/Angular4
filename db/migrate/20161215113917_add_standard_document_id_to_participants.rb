class AddStandardDocumentIdToParticipants < ActiveRecord::Migration
  def change
    add_column :participants, :standard_document_id, :integer, index: true
  end
end
