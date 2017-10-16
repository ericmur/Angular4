class AddPhaxioIdToFaxes < ActiveRecord::Migration
  def change
    add_column :faxes, :phaxio_id, :integer, index: true
  end
end
