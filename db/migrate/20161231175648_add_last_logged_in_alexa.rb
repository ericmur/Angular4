class AddLastLoggedInAlexa < ActiveRecord::Migration
  def change
    add_column :user_statistics, :last_logged_in_alexa, :datetime
  end
end
