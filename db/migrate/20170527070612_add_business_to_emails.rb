class AddBusinessToEmails < ActiveRecord::Migration
  def change
    add_reference :emails, :business, index: true, foreign_key: true
  end
end
