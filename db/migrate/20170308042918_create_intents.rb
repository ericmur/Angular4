class CreateIntents < ActiveRecord::Migration
  def change
    create_table :intents do |t|
      t.string :intent
      t.text   :utterance_hash
      t.text   :utterance_args_hash
      
      t.timestamps null: false
    end
  end
end
