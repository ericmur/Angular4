class Location < ActiveRecord::Base
  belongs_to :locationable, polymorphic: true
  validates :latitude, :longitude, presence: true
end
