class CreateDocytBotUserQuestions < ActiveRecord::Migration
  def change
    create_table :docyt_bot_user_questions do |t|
      t.references :user, index: true, foreign_key: true
      t.string :phone, index: true
      t.string :email, index: true
      t.text :query_string
      t.string :intent, index: true
      t.text :document_ids
      t.text :field_ids

      t.timestamps null: false
    end
  end
end
