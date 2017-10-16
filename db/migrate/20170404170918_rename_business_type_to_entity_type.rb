class RenameBusinessTypeToEntityType < ActiveRecord::Migration
  def change
    change_table :businesses do |t|
      t.rename :business_type, :entity_type
    end
  end
end
