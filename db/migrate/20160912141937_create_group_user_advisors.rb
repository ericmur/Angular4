class CreateGroupUserAdvisors < ActiveRecord::Migration
  def change
    create_table :group_user_advisors do |t|
      t.integer :advisor_id
      t.integer :group_user_id

      t.timestamps null: false
    end
    add_index :group_user_advisors, :advisor_id
    add_index :group_user_advisors, :group_user_id
  end
end
