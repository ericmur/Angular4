class CreateUserStatistics < ActiveRecord::Migration
  def change
    create_table :user_statistics do |t|
      t.references :user, index: true, foreign_key: true
      t.datetime :last_logged_in_web_app, index: true
      t.datetime :last_logged_in_iphone_app, index: true

      t.timestamps null: false
    end
  end
end
