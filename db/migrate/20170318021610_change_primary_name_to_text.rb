class ChangePrimaryNameToText < ActiveRecord::Migration
  def change
    change_column :standard_base_documents, :primary_name, :text
  end
end
