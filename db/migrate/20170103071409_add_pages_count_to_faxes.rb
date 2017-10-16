class AddPagesCountToFaxes < ActiveRecord::Migration
  def change
    add_column :faxes, :pages_count, :integer, default: 0
  end
end
