class AddIvToSymmetricKey < ActiveRecord::Migration
  def change
    add_column :symmetric_keys, :iv_encrypted, :text
  end
end
