class RemovePreCropS3ObjectKey < ActiveRecord::Migration
  def change
    remove_column :pages, :pre_crop_s3_object_key, :string
    remove_column :pages, :crop_rectangle_x, :integer
    remove_column :pages, :crop_rectangle_y, :integer
    remove_column :pages, :crop_rectangle_width, :integer
    remove_column :pages, :crop_rectangle_height, :integer
  end
end
