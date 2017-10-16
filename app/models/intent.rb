class Intent < ActiveRecord::Base
  MAX_SLOTS=3 #If you change this then you will need to change the NLP model code too
  SAMPLE_UTTERANCES=[
                     "What is my passport number",
                     "Show me my Chase Sapphire Credit Card",
                     "What is Jenny's passport number",
                     "Which of my documents are expiring in the next 2 months",
                     "Which of my bills are due this month",
                     "When is my drivers license expiring",
                     "Show me the total of my Konica Minolta invoices between January 2016 and March 2016",
                     "Show me the total of my meal receipts from January 2016",
                     "Show me the total of Michael's Avanti invoices from March 2016"
                    ]
  serialize :utterance_hash, JSON
  serialize :utterance_args_hash, JSON
  
  validates :utterance_hash, :presence => true
  validates :intent, :presence => true
  
  class_attribute :all_months_included
  class_attribute :all_field_names_included
  class_attribute :all_doc_names_included
  class_attribute :all_contact_types_included
  class_attribute :some_contact_names_included
  class_attribute :all_word_times_included
  
  def self.get_csv
    CSV.open("#{Rails.root}/utterances.csv", 'wb',
             :write_headers => true,
             :headers => ["text","intent",
                          "slot_name1","slot_value_start_index1","slot_value_end_index1",
                          "slot_name2","slot_value_start_index2","slot_value_end_index2",
                          "slot_name3","slot_value_start_index3","slot_value_end_index3"]
             ) do |csv|
      self.all.each do |intent|
        utterance = intent.utterance_hash
        utterance_args = intent.utterance_args_hash
        intent = intent.intent
        
        csv << [utterance % utterance_args.map { |arg| arg.values.first }, intent] + utterance_args.map { |arg| [arg.keys.first, nil, nil] }.flatten + [nil] * 3 * (MAX_SLOTS - utterance_args.count) #For each slot/arg there are 3 entries in csv: slot_name, slot_start_index, slot_end_index. We support max 3 slots
      end
    end
  end
  
  def self.load
    Intent.delete_all #Faster than destroy_all
    self.all_field_names_included = self.all_doc_names_included = false
    self.all_months_included = self.all_contact_types_included = self.some_contact_names_included = self.all_word_times_included = true
    
    intents_hash = JSON.parse(File.read("#{Rails.root}/config/utterances.json"))

    #Order intents_hash so that GetDocumentFieldInfo and GetDocumentsList intents are in the front. This is optimal to keep number of utterances generated at a low number
    intents_hash = intents_hash.to_a.select { |a| (a[0] == "GetDocumentFieldInfo" || a[1] == "GetDocumentsList") } + intents_hash.to_a.reject { |a| (a[0] == "GetDocumentFieldInfo" || a[1] == "GetDocumentsList") }
    intents_hash.each do |intent, samples_arr|
      samples_arr.each do |sample_arr|
        sample = sample_arr.first
        args = sample_arr
        args.shift
        arg_types = []
        args.each_with_index do |arg, i|
          arg_types << [arg, i]
        end
        
        prepared_args = []
        args.count.times { prepared_args << nil }
        case intent
        when ::Api::DocytBot::V1::IntentsService::GET_DOC_FIELD_INFO, ::Api::DocytBot::V1::IntentsService::GET_DOC_EXPIRATION_INFO
          add_sample(intent, sample, prepared_args, ["field_name", "document_name", "contact_type", "contact_name", "to_date"], arg_types, nil)
        when ::Api::DocytBot::V1::IntentsService::GET_DOCS_LIST
          add_sample(intent, sample, prepared_args, ["document_name", "contact_name", "contact_type", "to_date"], arg_types, nil)
        when ::Api::DocytBot::V1::IntentsService::GET_EXPIRING_DOCS_LIST, ::Api::DocytBot::V1::IntentsService::GET_EXPIRED_DOCS_LIST
          add_sample(intent, sample, prepared_args, ["document_name", "contact_name", "contact_type", "to_date"], arg_types, nil)
        when ::Api::DocytBot::V1::IntentsService::GET_DUE_DOCS_LIST, ::Api::DocytBot::V1::IntentsService::GET_PAST_DUE_DOCS_LIST
          add_sample(intent, sample, prepared_args, ["document_name", "contact_name", "contact_type", "to_date"], arg_types, nil)
        when ::Api::DocytBot::V1::IntentsService::GET_TOTAL_AMOUNT
          add_sample(intent, sample, prepared_args, ["merchant_name", "receipt_type", "to_date"], arg_types, nil)
        end
      end
    end
  end

  private
  
  def self.add_sample(intent, utterance, utterance_args, precedence_utterance_arg_types, utterance_arg_types, std_doc)
    if utterance_arg_types.blank?
      utterance_args = utterance_args.map { |utterance_arg| utterance_arg.inject({ }) { |h, (k, v)| h[k.downcase] = v.downcase; h } }
      Intent.create!(:utterance_hash => utterance.downcase, :utterance_args_hash => utterance_args, :intent => intent)
      return
    end
    first_match = false
    precedence_utterance_arg_types.each_with_index do |arg_type, i|
      matching_arg_type_obj = utterance_arg_types.find { |utterance_arg_type| utterance_arg_type[0] == arg_type }
      next if (matching_arg_type_obj.nil? or first_match)
      first_match = true
      
      matching_arg_index = matching_arg_type_obj[1]
      case arg_type
      when "field_name"
        process_field_name_arg_type(std_doc) { |std_doc, field|
          names = [field.name] + field.aliases.map { |alias_obj| alias_obj.name }
          names.each do |name|
            next if name.blank?
            utterance_args[matching_arg_index] = {"field_name" => "%%arg%%#{name}%%arg%%"}
            add_sample(intent, utterance, utterance_args, precedence_utterance_arg_types.slice(i+1..-1), utterance_arg_types.reject { |a| a[0] == arg_type }, field.standard_document)
          end
        }
      when "document_name"
        process_document_name_arg_type(std_doc) { |std_doc|
          next if (std_doc.blank? or std_doc.name.blank?)
          utterance_args[matching_arg_index] = { "document_name" => "%%arg%%#{std_doc.name}%%arg%%" }
          add_sample(intent, utterance, utterance_args, precedence_utterance_arg_types.slice(i+1..-1), utterance_arg_types.reject { |a| a[0] == arg_type }, std_doc)
        }
      when "contact_name"
        process_contact_name_arg_type(std_doc) { |std_doc, name|
          next if name.blank?
          utterance_args[matching_arg_index] = { "contact_name" => "%%arg%%#{name}%%arg%%" }
          add_sample(intent, utterance, utterance_args, precedence_utterance_arg_types.slice(i+1..-1), utterance_arg_types.reject { |a| a[0] == arg_type }, std_doc)
        }
      when "contact_type"
        process_contact_type_arg_type(std_doc) { |std_doc, contact_type|
          next if contact_type.blank?
          utterance_args[matching_arg_index] = { "contact_type" => "%%arg%%#{contact_type}%%arg%%" }
          add_sample(intent, utterance, utterance_args, precedence_utterance_arg_types.slice(i+1..-1), utterance_arg_types.reject { |a| a[0] == arg_type }, std_doc)
        }
      when "to_date"
        process_date_arg_type(std_doc, intent) { |std_doc, date|
          next if date.blank?
          utterance_args[matching_arg_index] = { "to_date" => "%%arg%%#{date}%%arg%%" }
          add_sample(intent, utterance, utterance_args, precedence_utterance_arg_types.slice(i+1..-1), utterance_arg_types.reject { |a| a[0] == arg_type }, std_doc)
        }
        return
      when "merchant_name"
        ["Konica Minolta", "Avanti", "Iron Mountain"].each do |merchant_name|
          utterance_args[matching_arg_index] = { "merchant_name" => "%%arg%%#{merchant_name}%%arg%%" }
          add_sample(intent, utterance, utterance_args, precedence_utterance_arg_types.slice(i+1..-1), utterance_arg_types.reject { |a| a[0] == arg_type }, nil)
        end
      when "receipt_type"
        ["meal", "travel", "gift", "other"].each do |merchant_name|
          utterance_args[matching_arg_index] = { "receipt_type" => "%%arg%%#{merchant_name}%%arg%%" }
          add_sample(intent, utterance, utterance_args, precedence_utterance_arg_types.slice(i+1..-1), utterance_arg_types.reject { |a| a[0] == arg_type }, nil)
        end
      else
        raise "Missed out processing #{arg_type}"
      end
    end
  end

  def self.process_date_arg_type(std_doc, intent, &block)
    # This parameter is used to ensure we only include all months values with the first document, so model is aware of all possible values of months. After first document we randomly give 2 values of month to subsequent utterances from other docs
    add_date = lambda { |std_doc|
      months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
      dates = (1..31).to_a
      years = (1940..2040).to_a
      years.shuffle.slice(0..0).each do |y|
        mos = months
        if self.all_months_included
          mos = months.shuffle.slice(0..0)
        end
        mos.each do |m|
          dates.shuffle.slice(0..0).each do |dt|
            block.call(std_doc, "#{m} #{dt}, #{y}")
            block.call(std_doc, "#{m} #{dt} #{y}")
            block.call(std_doc, "#{dt} #{m} #{y}")
            block.call(std_doc, "#{dt} #{m}")
            block.call(std_doc, "#{m} #{y}")
            block.call(std_doc, "#{y}")
          end
        end
      end
      if !self.all_months_included
        self.all_months_included = true
      end
      ["today", "tomorrow","next week", "last week", "last month", "next month", "last year", "next year"].shuffle.slice(0..0).each do |s|
        block.call(std_doc, s)
      end

      all_word_ns = ["two", "three", "four", "five", "six", "seven", "eight", "nine",1,2,3,4,5,6,7,8,9,10,11,12]
      if self.all_word_times_included
        all_word_ns = all_word_ns.shuffle.slice(0..0)
      end
      all_word_ns.each do |n|
        all_word_times = ["next one week", "in a week", ("next %s weeks" % n), "last one week", ("last %s weeks" % n), "last one month", ("last %s months" % n), "next one month", "in one month", ("next %s months" % n), ("in %s months" % n), "last one year", ("last %s year" % n), "next one year", ("next %s years" % n), ("in %s years" % n)]
        if self.all_word_times_included
          all_word_times = all_word_times.shuffle.slice(0..0)
        end
        all_word_times.shuffle.slice(0..0).each do |t|
          block.call(std_doc, t)
        end
      end

      if !self.all_word_times_included
        self.all_word_times_included = true
      end
    }
    if std_doc.nil?
      add_date.call(nil) #std_doc is not used at all. date is the first arg we are looking at.
    else
      add_date.call(std_doc)
    end
  end

  def self.process_field_name_arg_type(std_doc, &block)
    add_field = lambda { |field|
      block.call(std_doc, field)
    }
    if std_doc.nil?
      std_docs = StandardDocumentField.load_fields(false)
      if !self.all_field_names_included
        self.all_field_names_included = true
      else
        std_docs = std_docs.shuffle.slice(0..0)
      end
      std_docs.each(&add_field)
    else
      std_doc.standard_document_fields.each(&add_field)
    end
  end

  def self.process_document_name_arg_type(std_doc, &block)
    add_document = lambda { |std_doc|
      block.call(std_doc)
    }
    if std_doc.nil?
      std_docs = StandardDocument.only_system
      if !self.all_doc_names_included
        self.all_doc_names_included = true
      else
        std_docs = std_docs.order("RANDOM()").limit(1)
      end
      std_docs.each(&add_document)
    else
      add_document.call(std_doc)
    end
  end

  def self.process_descriptor_arg_type(std_doc, &block)
    add_descriptor = lambda { |std_doc|
      std_fields = std_doc.standard_document_fields.where(:primary_descriptor => true)
      field_values = [] #Array of arrays
      std_fields.each do |std_field|
        if std_field.data_type == 'state'
          if !self.some_state_descriptors_included
            self.some_state_descriptors_included = true
            field_values << StandardDocumentField.full_name_states.values
          else
            field_values << [StandardDocumentField.full_name_states.values.shuffle.first]   
          end
        elsif std_field.data_type == 'country'
          if !self.some_country_descriptors_included
            self.some_country_descriptors_included = true
            field_values << StandardDocumentField.nationalities.keys
          else
            field_values << [StandardDocumentField.nationalities.keys.shuffle.first]
          end
        else
          field_values << std_field.random_values(1)
        end
      end

      if field_values.count == 1
        field_values.first.each do |field_value|
          block.call(std_doc, field_value)
        end
      else
        combo_descriptor = []
        field_values.shuffle.each do |field_value_arr|
          combo_descriptor << field_value_arr.sample
        end
        field_value = combo_descriptor.join(" ")
        block.call(std_doc, field_value)
      end
    }
    
    if std_doc.nil?
      std_fields = StandardDocumentField.only_system.where(:primary_descriptor => true)

      if !self.some_descriptors_included
        self.some_descriptors_included = true
      else
        std_fields = std_fields.order("RANDOM").limit(1)
      end
      std_docs = std_fields.map { |std_f| std_f.standard_document }.uniq
      std_docs.each(&add_descriptor)
    else
      add_descriptor.call(std_doc)
    end
  end

  def self.process_contact_type_arg_type(std_doc, &block)
    contact_types = GroupUser::LABELS
    add_contact_type = lambda { |std_doc|
      if !self.all_contact_types_included
        self.all_contact_types_included = true
      else
        contact_types = [GroupUser::LABELS.shuffle.first]
      end
      contact_types.each do |contact_type|
        block.call(std_doc, contact_type)
      end
    }

    if std_doc.nil?
      std_docs = StandardDocument.only_system

      if !self.all_doc_names_included
        self.all_doc_names_included = true
      else
        std_docs = std_docs.order("RANDOM()").limit(1)
      end
      std_docs.each(&add_contact_type)
    else
      add_contact_type.call(std_doc)
    end
  end

  def self.process_contact_name_arg_type(std_doc, &block)
    users_first_names = User.order("RANDOM()").where.not(:first_name => nil).limit(2).map(&:first_name)
    group_users_first_names = GroupUser.order("RANDOM()").where.not(:name => nil).limit(2).map(&:first_name)
    clients_first_names = Client.order("RANDOM()").where.not(:name => nil).limit(2).map(&:first_name)

    first_names = (users_first_names + group_users_first_names + clients_first_names)

    users_full_names = User.order("RANDOM()").where.not(:first_name => nil).limit(2).map(&:name)
    group_users_full_names = GroupUser.order("RANDOM()").where.not(:name => nil).limit(2).map(&:name)
    clients_full_names = Client.order("RANDOM()").where.not(:name => nil).limit(2).map(&:name)
    full_names = (users_full_names + group_users_full_names + clients_full_names)

    if !self.some_contact_names_included
      self.some_contact_names_included = true
    else
      first_names = first_names.shuffle.slice(0..0)
      full_names = full_names.shuffle.slice(0..0)
    end
    
    add_contact_name = lambda { |std_doc|
      first_names.each do |first_name|
        block.call(std_doc, first_name)
      end

      full_names.each do |full_name|
        block.call(std_doc, full_name)
      end
    }
        
    if std_doc.nil?
      std_docs = StandardDocument.only_system

      if !self.all_doc_names_included
        self.self.all_doc_names_included = true
      else
        std_docs = std_docs.order("RANDOM()").limit(1)
      end
      std_docs.each(&add_contact_name)
    else
      add_contact_name.call(std_doc)
    end
  end
end
