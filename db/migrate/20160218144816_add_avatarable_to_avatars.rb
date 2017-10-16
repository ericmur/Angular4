class AddAvatarableToAvatars < ActiveRecord::Migration
  def change
    add_column :avatars, :avatarable_id, :integer
    add_column :avatars, :avatarable_type, :string

    Avatar.find_each(batch_size: 100) do |avatar|
      avatar.avatarable_id = avatar.user_id
      avatar.avatarable_type = 'User'
      avatar.save
    end

    remove_column :avatars, :user_id, :integer
  end
end
