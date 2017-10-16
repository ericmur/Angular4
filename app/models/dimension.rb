class Dimension < ActiveRecord::Base
  has_many :standard_documents #No dependent => destroy/nullify here. The self.load method destroys and recreates Dimensions from config file with the exactly same ids. 
  validates :width, :presence => true
  validates :height, :presence => true
  validates :unit, :presence => true
  validates :name, :presence => true

  def self.load
    dimensions = JSON.parse(File.read("#{Rails.root}/config/dimensions.json"))
    self.destroy_all
    dimensions.each do |name, hash|
      dimension = Dimension.create!(:id => hash["id"], :width => hash["width"], :height => hash["height"], :unit => hash["unit"], :name => hash["name"])
    end
  end
end
