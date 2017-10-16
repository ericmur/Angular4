class CreateCloudServicePaths < ActiveRecord::Migration
  def change
    create_table :cloud_service_paths do |t|
      t.references :consumer, index: true
      t.references :cloud_service, index: true
      t.string :path
      t.string :hash_sum
      t.datetime :processed_at
      t.timestamps
    end
  end
end