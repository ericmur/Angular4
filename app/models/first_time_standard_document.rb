class FirstTimeStandardDocument < ActiveRecord::Base
  belongs_to :standard_document
  belongs_to :consumer_account_type

  scope :by_account_type, lambda { |acc_type_id|
    where(:consumer_account_type_id => acc_type_id) 
  }

  def self.load
    ActiveRecord::Base.transaction do
      self.load_no_transaction
    end
  end

  def self.load_no_transaction
    docs = JSON.parse(File.read("#{Rails.root}/config/standard_base_documents.json"))
    first_time_standard_docs = JSON.parse(File.read("#{Rails.root}/config/first_time_standard_documents.json"))
    account_types = JSON.parse(ERB.new(File.read("#{Rails.root}/config/consumer_account_types.json.erb")).result)
    FirstTimeStandardDocument.destroy_all
    first_time_standard_docs.each do |account_type_name, st_docs|
      account_type_id = account_types[account_type_name]["id"]
      st_docs.each do |st_doc_key|
        FirstTimeStandardDocument.create!(:standard_document_id => docs[st_doc_key]["id"], :consumer_account_type_id => account_type_id)
      end
    end
  end
end
