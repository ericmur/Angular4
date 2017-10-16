class CreateReviews < ActiveRecord::Migration
  def change
    create_table :reviews do |t|
      t.references :user, index: true, foreign_key: true
      t.string :last_version
      t.boolean :refused, default: false

      t.timestamps null: false
    end
  end
end
