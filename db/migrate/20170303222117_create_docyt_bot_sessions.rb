class CreateDocytBotSessions < ActiveRecord::Migration
  def change
    create_table :docyt_bot_sessions do |t|
      t.string :session_token
      
      t.timestamps null: false
    end

    add_index :docyt_bot_sessions, :session_token, unique: true
  end
end
