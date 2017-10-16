class AddStructureTypeToClients < ActiveRecord::Migration
  def change
    add_column :clients, :structure_type, :string
  end
end
