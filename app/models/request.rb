class Request < ActiveRecord::Base
  belongs_to :workflow
  belongs_to :requestionable, polymorphic: true

  validates :requestionable_type, :requestionable_id, presence: true
end
