class CreateAdvisorData < ActiveRecord::Migration
  def change
    create_table :advisor_data do |t|
      t.belongs_to :advisor, index: true
      t.integer :advisor_type
      t.timestamps null: false
    end
  end
end
