class RemoveReadAtColumnFromMessage < ActiveRecord::Migration
  def change
    remove_column :messages, :read_at, :datetime
  end
end
