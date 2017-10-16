class AddMoreS3ObjectsToPage < ActiveRecord::Migration
  def change
    add_column :pages, :pre_crop_s3_object_key, :string
    add_column :pages, :original_s3_object_key, :string
    add_column :pages, :crop_rectangle_x, :integer
    add_column :pages, :crop_rectangle_y, :integer
    add_column :pages, :crop_rectangle_width, :integer
    add_column :pages, :crop_rectangle_height, :integer
  end
end
