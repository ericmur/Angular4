class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string  :email
      t.string  :encrypted_pin
      t.string  :salt
      t.text    :private_key
      t.text    :public_key
      t.string  :type
      t.string  :phone
      t.string  :phone_normalized
      t.timestamps
    end
  end
end
