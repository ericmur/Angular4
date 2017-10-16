#Do not add :dependent => nullify to this model for its associations. This is so we can create the relationship with standard_document (for the associations) again when categories are restructured. During restructuring we call StandardBaseDocument.load which re-creates the categories structure
class ConsumerAccountType < ActiveRecord::Base
  INDIVIDUAL = 1
  BUSINESS = 2
  FREE_FOREVER = 3

  MAX_PAGES_INDIVIDUAL = 500
  MAX_PAGES_BUSINESS = 2000
  MAX_PAGES_FREE = 25
  
  has_many :consumers, :class_name => 'User' #, :dependent => :nullify - do not dependent nullify for the reason above
  validates :display_name, :presence => true, :uniqueness => true

  scope :individual_type, lambda {
    where(:id => INDIVIDUAL)
  }

  scope :business_type, lambda {
    where(:id => BUSINESS)
  }

  scope :free_forever_type, lambda {
    where(:id => FREE_FOREVER)
  }

  def business?
    id == BUSINESS
  end

  def individual?
    id == INDIVIDUAL
  end

  def free_forever?
    id == FREE_FOREVER
  end

  def standard_folders
    StandardBaseDocumentAccountType.for_consumer_account_type(id).for_standard_folders.map{ |d| d.standard_base_document }
  end

  def standard_documents
    StandardBaseDocumentAccountType.for_consumer_account_type(id).for_standard_documents.map{ |d| d.standard_base_document }
  end

  def self.load
    ActiveRecord::Base.transaction do
      account_types = JSON.parse(ERB.new(File.read("#{Rails.root}/config/consumer_account_types.json.erb")).result)
      ConsumerAccountType.destroy_all
      account_types.each do |acc_type_key, acc_type_hash|
        acc_type = ConsumerAccountType.new(:id => acc_type_hash["id"], :display_name => acc_type_hash["display_name"], :monthly_pricing => acc_type_hash["monthly_pricing"], :annual_pricing => acc_type_hash["annual_pricing"])
        acc_type.save!
      end
    end
  end
end
