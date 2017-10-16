class CreateConsumerFolderAccountTypes < ActiveRecord::Migration
  def change
    create_table :consumer_folder_account_types do |t|
      t.references :standard_folder, :index => true
      t.references :consumer_account_type, :index => true
      t.boolean    :show, :default => true
      t.timestamps null: false
    end
  end
end
