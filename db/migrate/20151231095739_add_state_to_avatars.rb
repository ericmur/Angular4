class AddStateToAvatars < ActiveRecord::Migration
  def change
    add_column :avatars, :state, :string
  end
end
