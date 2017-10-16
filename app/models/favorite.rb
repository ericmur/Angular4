class Favorite < ActiveRecord::Base
  belongs_to :consumer, :class_name => 'User'
  belongs_to :document

  default_scope { order(rank: :asc) }
  
  validates :document_id, :presence => true, :uniqueness => { :scope => :consumer_id }
  validates :rank, :presence => true, :uniqueness => { :scope => :consumer_id }

  before_validation :add_rank_if_missing, :on => :create

  private
  def add_rank_if_missing
    self.rank = Favorite.where(:consumer_id => self.consumer_id).maximum(:rank).to_i + 1
  end
end
