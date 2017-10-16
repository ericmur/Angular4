class AddLocationableToLocations < ActiveRecord::Migration
  def change
    add_reference :locations, :locationable, polymorphic: true, index: true
    remove_reference :locations, :user
  end
end
