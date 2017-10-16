class StandardCategory < ActiveRecord::Base
  DOCYT_SUPPORT_ID = 6
  has_many :advisors, :class_name => 'User' #Do not dependent nullify or destroy so the associated standard_category_id is not lost when we run StandardCategory.load
  has_many :advisor_default_folders, :dependent => :destroy
  
  belongs_to :consumer, :class_name => 'User' #This is the user that created this custom standard category. We don't support this yet, but we will in very near future.

  validates :name, presence: true
  validates :name, :uniqueness => { :scope => :consumer_id }
  
  scope :only_system, -> { where(consumer_id: nil) }
  scope :for_user, -> (user) { where(consumer_id: user.id) }
  scope :except_support, -> { where.not(id: DOCYT_SUPPORT_ID) }

  def self.load
    ActiveRecord::Base.transaction do
      advisor_categories = JSON.parse(ERB.new(File.read("#{Rails.root}/config/standard_categories.json.erb")).result)
      family_folder_structure_json = JSON.parse(File.read("#{Rails.root}/config/standard_base_documents_structure.json"))
      biz_folder_structure_json = JSON.parse(File.read("#{Rails.root}/config/standard_base_documents_business_structure.json"))

      folder_structure_json = family_folder_structure_json.merge(biz_folder_structure_json)

      category_ids = StandardCategory.where.not(:consumer_id => nil).select(:id)

      self.where.not(:id => category_ids).delete_all #We skip consumer created custom Categories. Only Standard ones are deleted and recreated. Use delete_all instead of destroy_all so that we don't destroy any associated categories and advisors in those categories
      AdvisorDefaultFolder.destroy_all
      
      advisor_categories.each do |category, category_hash|
        name = category_hash["display_name"]
        id = category_hash["id"]
        advisor_category = StandardCategory.create!(:id => id, :name => name)

        if category_hash["standard_folders"]
          category_hash["standard_folders"].each do |category_name|
            folder_json = folder_structure_json.select { |key, hash| key == category_name }
            category_id = folder_json[category_name]["id"]
            std_folder = StandardFolder.only_category.only_system.where(:id => category_id).first
            advisor_category.advisor_default_folders.create!(:standard_folder_id => std_folder.id)
          end
        end
      end
    end
  end
end
