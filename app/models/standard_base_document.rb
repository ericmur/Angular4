class StandardBaseDocument < ActiveRecord::Base
  
  #rank field is used for ranking categories
  has_many :standard_folder_standard_documents, :dependent => :destroy
  has_many :owners, :class_name => 'StandardBaseDocumentOwner', :dependent => :destroy
  has_many :permissions, dependent: :destroy
  has_many :standard_base_document_account_types, foreign_key: 'standard_folder_id', dependent: :destroy
  serialize :primary_name, JSON
  
  belongs_to :created_by, :foreign_key => 'consumer_id', :class_name => 'User' #Always better to use class_name instead of class as otherwise it could cause circular dependency. Since using :class => User would invoke rails code inside User.rb while loading this relationship

  validates :name, presence: true, length: { maximum: 120 }
  validates :type, presence: true, inclusion: { in: %w(StandardDocument StandardFolder) }
  validates :size, inclusion: { in: %w[Card Page Booklet] }, :allow_nil => true
  scope :only_category, -> { where(category: true) }
  scope :only_system, -> { where(consumer_id: nil) }
  scope :only_custom, -> { where.not(consumer_id: nil) }
  validates :consumer_id, presence: true, :if => Proc.new { |obj| obj.owners.first }

  scope :for_consumer_and_group_users_of, -> (consumer) {
    owner_list = consumer.group_users_as_group_owner.map {|g| [g.owner_id, g.owner_type] } << [consumer.id, consumer.class.to_s]
    conds = owner_list.map do |e|
      owner_types = e[1] == "GroupUser" ? ["\'#{e[1]}\'"] : ["\'User\'", "\'Consumer\'"]
      "(standard_base_document_owners.owner_id = #{e[0]} AND standard_base_document_owners.owner_type in (#{owner_types.join(',')}))"
    end.join(" OR ")
    joins(:owners).where(conds)
  }

  scope :viewable_by_user, -> (user_id) {
    joins(:permissions).where(permissions: { user_id: user_id, value: Permission::VIEW }).distinct
  }

  scope :owned_by, -> (user_or_group_user) {
    owner_type = user_or_group_user.class.to_s == "GroupUser" ? ["GroupUser"] : ["User", "Consumer"]
    joins(:owners).where(standard_base_document_owners: { owner_id: user_or_group_user.id, owner_type: owner_type } )
  }

  validate do |standard_base_document|
    if standard_base_document.consumer_id
      if standard_base_document.owners.first.nil?
        standard_base_document.errors[:base] << "No owner provided when creating standard_base_document"
      end
    end

    stdoc_owners = standard_base_document.owners.select { |d| d.owner_type == GroupUser.to_s }
    if stdoc_owners.map { |stdoc_owner| stdoc_owner.owner.user_id }.include?(standard_base_document.created_by_id)
      standard_base_document.errors[:base] << "Cannot create document type for a relationship user instead create it into the user's account when it is the same user"
    end
  end

  def business_document?
    standard_base_document_account_types.where(consumer_account_type_id: ConsumerAccountType::BUSINESS).exists?
  end

  def individual_document?
    standard_base_document_account_types.where(consumer_account_type_id: ConsumerAccountType::INDIVIDUAL).exists?
  end

  def created_by_id
    self.consumer_id
  end

  def is_writeable_by_user?(user)
    permissions.where(user_id: user, value: Permission::WRITE).exists?
  end

  def is_editable_by_user?(u)
    consumer = u.becomes(Consumer)
    return (consumer.standard_base_document_ownerships.where(:standard_base_document_id => self.id).first or
      (self.created_by == consumer and self.owners.where(:owner_type => GroupUser.to_s).includes(:owner).to_a.find { |sbd_owner| sbd_owner.owner.user_id }.nil?) or
      consumer.user_accesses.where(:user_id => self.owners.where(:owner_type => ['User', 'Consumer']).select(:owner_id)).first)
  end

  def is_destroyable_by_user?(user, folder_structure_owner)
    return false if self.consumer_id.blank?
    self.permissions.where(user_id: user, folder_structure_owner: folder_structure_owner, value: Permission::DELETE).exists?
  end

  # This mostly used for cache updates
  def consumer_ids_for_owners
    consumer_ids = self.owners.map do |doc_owner|
      if doc_owner.owner_type == "GroupUser"
        doc_owner.owner.group.owner.id
      elsif %w[User Consumer].include?(doc_owner.owner_type)
        doc_owner.owner.id
      else
        nil
      end
    end
    consumer_ids << self.consumer_id # always include uploader/creator of standard_base_document
    consumer_ids.uniq.reject(&:blank?)
  end
  
  def self.load
    ActiveRecord::Base.transaction do
      FieldValueSuggestion.where(user_id: nil).destroy_all # Note: ActiveRecord rollback will not revert this deletion
      #Destroy all but consumer created StandardBaseDocuments. If this creates any dangling StandardBaseDocuments created by consumer then we will have consumer put those documents at another place.
      doc_ids = StandardBaseDocument.where.not(:consumer_id => nil).select(:id)
      folder_doc_ids = StandardFolderStandardDocument.where(:standard_base_document_id => doc_ids).select(:standard_folder_id)
      self.where.not(:id => doc_ids.map(&:id) + folder_doc_ids.map(&:standard_folder_id)).where(consumer_id: nil).destroy_all

      # Can be destroy_all to but just being safe incase we add other associations in future and forget to check against cascading destroy here.
      StandardBaseDocumentAccountType.joins(:standard_base_document).where(standard_base_documents: { consumer_id: nil }).delete_all

      StandardFolder.where(:id => folder_doc_ids.map(&:standard_folder_id)).where(consumer_id: nil).delete_all #Use delete_all so that we don't delete standard_folder_standard_documents entries for the consumer's standard_documents that are inside this StandardFolder
      docs = JSON.parse(File.read("#{Rails.root}/config/standard_base_documents.json"))
      docs_structure = JSON.parse(File.read("#{Rails.root}/config/standard_base_documents_structure.json"))
      account_types = JSON.parse(ERB.new(File.read("#{Rails.root}/config/consumer_account_types.json.erb")).result)
      dimensions = JSON.parse(File.read("#{Rails.root}/config/dimensions.json"))
      business_docs_structure = JSON.parse(File.read("#{Rails.root}/config/standard_base_documents_business_structure.json"))      

      business_docs_structure.each do |category, category_hash|
        acc_type = "BUSINESS"
        process_category(acc_type, category, category_hash, docs)
      end
      
      docs_structure.each do |category, category_hash|
        acc_type = "INDIVIDUAL"
        process_category(acc_type, category, category_hash, docs)
      end
      
      #Load Favorites
      favorites = JSON.parse(File.read("#{Rails.root}/config/favorites.json"))
      DefaultFavorite.destroy_all
      favorites.each do |favorite_key|
        doc_hash = docs[favorite_key]
        favorite = DefaultFavorite.new(:standard_document_id => doc_hash["id"])
        favorite.save!
      end

      #Load first time standard documents
      FirstTimeStandardDocument.load_no_transaction
    end

    DocumentCacheService.new(nil, { only_system: '1' }).update_system_document_caches

    unless Rails.env.test?
      puts "IMPORTANT:"
      puts "Please update users document json. By running this task:"
      puts "RAILS_ENV=#{Rails.env} bundle exec rake document_cache:update_users_document_json"
    end
  end

  private

  def self.process_category(acc_type, category, category_hash, docs)
    account_types = JSON.parse(ERB.new(File.read("#{Rails.root}/config/consumer_account_types.json.erb")).result)
    dimensions = JSON.parse(File.read("#{Rails.root}/config/dimensions.json"))
    
    category_id = category_hash["id"]
    name = category_hash["display_name"]
    icons = category_hash["icons"]
    description = category_hash["description"]
    document_keys = category_hash["documents"]
    show = category_hash["show"] ? category_hash["show"] : true
    docs_with_pages = category_hash["pages"]
    
    category = StandardFolder.new(:id => category_id, :name => name, :icon_name_1x => icons[0], :icon_name_2x => icons[1], :icon_name_3x => icons[2], :description => description, :default => true, :with_pages => docs_with_pages)
    category.category = true
    category.save!

    consumer_acc_type = ConsumerAccountType.where(:id => account_types[acc_type]["id"]).first
    folder_acc_type = category.standard_base_document_account_types.build(:consumer_account_type_id => consumer_acc_type.id, :show => show)
    folder_acc_type.save!
    
    document_keys.each do |doc_key|
      doc_hash = docs[doc_key]
      raise "doc_hash: #{doc_key}" if docs[doc_key].nil?
      doc = StandardBaseDocument.where(:id => doc_hash["id"]).first
      if doc
        if doc_hash["display_name"] != doc.name
          raise "Multiple entries found for #{doc_hash['id']}"
        end
      else
        raise "No non group type supported" if doc_hash["type"] != "group"
        doc_icons = doc_hash["icons"]
        if doc_hash["dimension"]
          dimension_id = dimensions[doc_hash["dimension"]]["id"]
        else
          dimension_id = nil
        end
        primary_name = doc_hash["primary_name"]
        doc = StandardDocument.new(:name => doc_hash["display_name"], :id => doc_hash["id"], :size => doc_hash["size"], :default => doc_hash["show"], :category => false, :with_pages => doc_hash["pages"], :dimension_id => dimension_id, :primary_name => primary_name)
        if doc_icons.present? && doc_icons.count == 3
          doc.icon_name_1x = doc_icons[0]
          doc.icon_name_2x = doc_icons[1]
          doc.icon_name_3x = doc_icons[2]
        end
        
        if doc_hash["aliases"]
          doc_hash["aliases"].each do |alias_name|
            doc.aliases.build(:name => alias_name)
          end
        end

        category.standard_base_document_account_types.each do |standard_base_document_account_type|
          doc.standard_base_document_account_types.build(consumer_account_type_id: standard_base_document_account_type.consumer_account_type_id, show: doc_hash["show"])
        end

        doc.save!
        
        if doc_hash["fields"]
          doc_hash["fields"].each do |field, field_hash|
            if field_hash["data_type"] == "expiry_date"
              std_f = doc.standard_document_fields.build(:field_id => field_hash["field_id"], :name => field_hash["display_name"], :data_type => field_hash["data_type"], min_year: field_hash["min_year"], max_year: field_hash["max_year"], type: "StandardDocumentField")
            elsif field_hash["data_type"] == "due_date"
              std_f = doc.standard_document_fields.build(:field_id => field_hash["field_id"], :name => field_hash["display_name"], :data_type => field_hash["data_type"], min_year: field_hash["min_year"], max_year: field_hash["max_year"], type: "StandardDocumentField")
            elsif field_hash["data_type"] == "date"
              std_f = doc.standard_document_fields.build(:field_id => field_hash["field_id"], :name => field_hash["display_name"], :data_type => field_hash["data_type"], min_year: field_hash["min_year"], max_year: field_hash["max_year"], type: "StandardDocumentField")
            else
              std_f = doc.standard_document_fields.build(:field_id => field_hash["field_id"], :name => field_hash["display_name"], :data_type => field_hash["data_type"], type: "StandardDocumentField")
            end
            
            std_f.encryption = field_hash["encryption"] == true
            std_f.notify = field_hash["notify"] == true
            std_f.speech_text = field_hash["speech_text"]
            std_f.speech_text_contact = field_hash["speech_text_contact"]
            std_f.primary_descriptor = field_hash["primary_descriptor"] if field_hash["primary_descriptor"]
            std_f.suggestions = field_hash["suggestions"] if field_hash["suggestions"]
            std_f.data_type_values = field_hash["data_type_values"] if field_hash["data_type_values"]

            if field_hash["aliases"]
              field_hash["aliases"].each do |alias_name|
                std_f.aliases.build(:name => alias_name)
              end
            end
            if field_hash["notify_durations"]
              field_hash["notify_durations"].each do |notify_field_hash|
                std_f.notify_durations.build(amount: notify_field_hash["amount"], unit: notify_field_hash["unit"])
              end
            end
            
            unless std_f.save
              raise "Could not save standard_document_field: " + field_hash.inspect + " " + std_f.errors.full_messages.inspect
            else
              field_hash["value_suggestions"].each do |value|
                FieldValueSuggestion.create_suggestion_for_field(nil, doc.id, std_f.name, value)
              end unless field_hash["value_suggestions"].blank?
            end
          end
        end
      end
      
      #We want rank to be set ahead of consumer documents in that folder, so consumer documents show up after system documents. It might be that one of the documents might ending up getting same rank as a consumer document. Its not a big deal even if 2 documents have same rank. Those documents with same rank will show up in the app in any order (which is OK)
      highest_rank_row = StandardFolderStandardDocument.with_parent_folder(category.id).only_system_standard_documents().order(rank: :desc).first
      highest_rank = highest_rank_row ? (highest_rank_row.rank + 1) : 1
      
      sfsd = category.standard_folder_standard_documents.build(:standard_base_document_id => doc.id, :rank => highest_rank)
      sfsd.save!
    end
  end
end
