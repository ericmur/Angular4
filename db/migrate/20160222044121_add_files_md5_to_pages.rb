class AddFilesMd5ToPages < ActiveRecord::Migration
  def change
    add_column :pages, :original_file_md5, :string
    add_column :pages, :final_file_md5, :string
  end
end
