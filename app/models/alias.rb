class Alias < ActiveRecord::Base
  belongs_to :aliasable, :polymorphic => true

  validates :name, :presence => true
  validates :name, :uniqueness => { scope: [:aliasable_id, :aliasable_type] }
end
