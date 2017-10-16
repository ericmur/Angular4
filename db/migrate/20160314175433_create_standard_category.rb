class CreateStandardCategory < ActiveRecord::Migration
  def change
    create_table :standard_categories do |t|
      t.string  :name
      t.belongs_to :consumer
    end
  end
end
