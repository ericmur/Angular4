class AddEmailIdToDocument < ActiveRecord::Migration
  def change
    add_reference :documents, :email, :index => true
  end
end
