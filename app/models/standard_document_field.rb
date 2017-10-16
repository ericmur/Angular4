# -*- coding: utf-8 -*-
class StandardDocumentField < BaseDocumentField
  belongs_to :standard_document
  validates :field_id, presence: true, uniqueness: { scope: :standard_document_id } #Cannot be nil as it is a fixed id set by standard_base_documents:load. This id cannot change so the associations are not broken when standard_base_documents:load is run again.
  serialize :speech_text, JSON
  serialize :speech_text_contact, JSON

  scope :only_system, lambda { where(:created_by_user_id => nil) }
  
  #This loads newline separated fields that will be used in slots in Alexa
  def self.load_fields(request_field_names = true)
    docs = JSON.parse(File.read("#{Rails.root}/config/standard_base_documents.json"))
    slots = JSON.parse(File.read("#{Rails.root}/config/speech_field_slots.json"))
    output_slots = []
    output_fields = []
    slots.each do |doc_type, field_hash|
      fs = docs[doc_type]["fields"].values.select { |hsh|
        hsh["field_id"] == field_hash["field_id"]
      }
      raise "More than 1 matching fields found for #{doc_type}" if fs.count > 1
      f = fs.first
      raise "Invalid configuration. Slots.json has #{field_hash['display_name']}, while docs.json has #{f['display_name']}" if field_hash['display_name'] != f['display_name']
      std_doc = StandardDocument.where(:id => docs[doc_type]["id"]).first
      f_obj = std_doc.standard_document_fields.where(:field_id => f['field_id']).first
      output_slots << f['display_name']
      output_fields << f_obj
      f['aliases'].each do |alias_name|
        output_slots << alias_name
      end if f['aliases']
    end
    if request_field_names
      output_slots
    else
      output_fields
    end
  end

  def compile_speech_text_for_contact(doc, u, first_name, &speech_block)
    if self.speech_text_contact[1]
      args = self.speech_text_contact[1].map do |arg|
        if arg == "first_name"
          first_name
        elsif arg["raw"]
          compile_speech_text_raw_value(arg, &speech_block)
        else
          compile_speech_text_field_value(arg, doc, u, &speech_block)
        end
      end
      self.speech_text_contact[0] % args
    else
      self.speech_text_contact[0]
    end
  end

  def compile_speech_text(doc, u, &speech_block)
    if self.speech_text[1]
      args = self.speech_text[1].map do |arg|
        if arg["raw"]
          compile_speech_text_raw_value(arg, &speech_block)
        else
          compile_speech_text_field_value(arg, doc, u, &speech_block)
        end
      end
      self.speech_text[0] % args
    else
      self.speech_text[0]
    end
  end

  def random_values(cnt)
    DocumentFieldValue.joins(:document).where(:local_standard_document_field_id => self.field_id).where(["documents.standard_document_id = ?", self.standard_document_id]).order("RANDOM()").limit(cnt).pluck(:value)
  end

  def self.full_name_states
    { 'AL' => 'Alabama',
      'AK' => 'Alaska',
      'AS' => 'America Samoa',
      'AZ' => 'Arizona',
      'AR' => 'Arkansas',
      'CA' => 'California',
      'CO' => 'Colorado',
      'CT' => 'Connecticut',
      'DE' => 'Delaware',
      'DC' => 'District of Columbia',
      'FM' => 'Micronesia1',
      'FL' => 'Florida',
      'GA' => 'Georgia',
      'GU' => 'Guam',
      'HI' => 'Hawaii',
      'ID' => 'Idaho',
      'IL' => 'Illinois',
      'IN' => 'Indiana',
      'IA' => 'Iowa',
      'KS' => 'Kansas',
      'KY' => 'Kentucky',
      'LA' => 'Louisiana',
      'ME' => 'Maine',
      'MH' => 'Islands1',
      'MD' => 'Maryland',
      'MA' => 'Massachusetts',
      'MI' => 'Michigan',
      'MN' => 'Minnesota',
      'MS' => 'Mississippi',
      'MO' => 'Missouri',
      'MT' => 'Montana',
      'NE' => 'Nebraska',
      'NV' => 'Nevada',
      'NH' => 'New Hampshire',
      'NJ' => 'New Jersey',
      'NM' => 'New Mexico',
      'NY' => 'New York',
      'NC' => 'North Carolina',
      'ND' => 'North Dakota',
      'OH' => 'Ohio',
      'OK' => 'Oklahoma',
      'OR' => 'Oregon',
      'PW' => 'Palau',
      'PA' => 'Pennsylvania',
      'PR' => 'Puerto Rico',
      'RI' => 'Rhode Island',
      'SC' => 'South Carolina',
      'SD' => 'South Dakota',
      'TN' => 'Tennessee',
      'TX' => 'Texas',
      'UT' => 'Utah',
      'VT' => 'Vermont',
      'VI' => 'Virgin Island',
      'VA' => 'Virginia',
      'WA' => 'Washington',
      'WV' => 'West Virginia',
      'WI' => 'Wisconsin',
      'WY' => 'Wyoming'
    }
  end

  def self.nationalities
    {
      "Afghanistan"=>"Afghan",
      "Albania"=>"Albanian",
      "Algeria"=>"Algerian",
      "Andorra"=>"Andorran",
      "Angola"=>"Angolan",
      "Argentina"=>"Argentinian",
      "Armenia"=>"Armenian",
      "Australia"=>"Australian",
      "Austria"=>"Austrian",
      "Azerbaijan"=>"Azerbaijani",
      "Bahamas"=>"Bahamian",
      "Bahrain"=>"Bahraini",
      "Bangladesh"=>"Bangladeshi",
      "Barbados"=>"Barbadian",
      "Belarus"=>"Belarusian",
      "Belgium"=>"Belgian",
      "Belize"=>"Belizean",
      "Benin"=>"Beninese",
      "Bhutan"=>"Bhutanese",
      "Bolivia"=>"Bolivian",
      "Bosnia-Herzegovina"=>"Bosnian",
      "Botswana"=>"Botswanan",
      "Brazil"=>"Brazilian",
      "Britain"=>"British",
      "Brunei"=>"Bruneian",
      "Bulgaria"=>"Bulgarian",
      "Burkina"=>"Burkinese",
      "Myanmar"=>"Burmese",
      "Burundi"=>"Burundian",
      "Cambodia"=>"Cambodian",
      "Cameroon"=>"Cameroonian",
      "Canada"=>"Canadian",
      "Cape Verde Islands"=>"Cape Verdean",
      "Chad"=>"Chadian",
      "Chile"=>"Chilean",
      "China"=>"Chinese",
      "Colombia"=>"Colombian",
      "Congo"=>"Congolese",
      "Costa Rica"=>"Costa Rican",
      "Croatia"=>"Croat or Croatian",
      "Cuba"=>"Cuban",
      "Cyprus"=>"Cypriot",
      "Czech Republic"=>"Czech",
      "Denmark"=>"Danish", "Djibouti"=>"Djiboutian", "Dominica"=>"Dominican", "Dominican Republic"=>"Dominican",
      "Ecuador"=>"Ecuadorean", "Egypt"=>"Egyptian", "El Salvador"=>"Salvadorean", "England"=>"English", "Eritrea"=>"Eritrean", "Estonia"=>"Estonian", "Ethiopia"=>"Ethiopian",
      "Fiji"=>"Fijian", "Finland"=>"Finnish", "France"=>"French",
      "Gabon"=>"Gabonese", "Gambia"=>"Gambian", "Georgia"=>"Georgian", "Germany"=>"German", "Ghana"=>"Ghanaian", "Greece"=>"Greek", "Grenada"=>"Grenadian", "Guatemala"=>"Guatemalan", "Guinea"=>"Guinean", "Guyana"=>"Guyanese",
      "Haiti"=>"Haitian", "Holland"=>"Dutch", "Honduras"=>"Honduran", "Hungary"=>"Hungarian",
      "Iceland"=>"Icelandic", "India"=>"Indian", "Indonesia"=>"Indonesian", "Iran"=>"Iranian", "Iraq"=>"Iraqi", "Ireland"=>"Irish", "Italy"=>"Italian",
      "Jamaica"=>"Jamaican", "Japan"=>"Japanese", "Jordan"=>"Jordanian",
      "Kazakhstan"=>"Kazakh", "Kenya"=>"Kenyan", "Kuwait"=>"Kuwaiti",
      "Laos"=>"Laotian", "Latvia"=>"Latvian", "Lebanon"=>"Lebanese", "Liberia"=>"Liberian", "Libya"=>"Libyan", "Liechtenstein"=>"-", "Lithuania"=>"Lithuanian", "Luxembourg"=>"-",
      "Macedonia"=>"Macedonian", "Madagascar"=>"Malagasy", "Malawi"=>"Malawian", "Malaysia"=>"Malaysian", "Maldives"=>"Maldivian", "Mali"=>"Malian", "Malta"=>"Maltese", "Mauritania"=>"Mauritanian", "Mauritius"=>"Mauritian", "Mexico"=>"Mexican", "Moldova"=>"Moldovan", "Monaco"=>"Monacan", "Mongolia"=>"Mongolian", "Montenegro"=>"Montenegrin", "Morocco"=>"Moroccan", "Mozambique"=>"Mozambican",
      "Namibia"=>"Namibian", "Nepal"=>"Nepalese", "Netherlands"=>"Dutch", "New Zealand"=>"New Zealand", "Nicaragua"=>"Nicaraguan", "Niger"=>"Nigerien", "Nigeria"=>"Nigerian", "North Korea"=>"North Korean", "Norway"=>"Norwegian",
      "Oman"=>"Omani",
      "Pakistan"=>"Pakistani", "Panama"=>"Panamanian", "Papua New Guinea"=>"Papua New Guinean", "Paraguay"=>"Paraguayan", "Peru"=>"Peruvian", "the Philippines"=>"Philippine", "Poland"=>"Polish", "Portugal"=>"Portuguese",
      "Qatar"=>"Qatari",
      "Romania"=>"Romanian", "Russia"=>"Russian", "Rwanda"=>"Rwandan",
      "Saudi Arabia"=>"Saudi", "Scotland"=>"Scottish", "Senegal"=>"Senegalese", "Serbia"=>"Serbian", "Seychelles"=>"Seychellois", "Sierra Leone"=>"Sierra Leonian", "Singapore"=>"Singaporean", "Slovakia"=>"Slovak", "Slovenia"=>"Slovenian", "Somalia"=>"Somali", "South Africa"=>"South African", "South Korea"=>"South Korean", "Spain"=>"Spanish", "Sri Lanka"=>"Sri Lankan", "Sudan"=>"Sudanese", "Suriname"=>"Surinamese", "Swaziland"=>"Swazi", "Sweden"=>"Swedish", "Switzerland"=>"Swiss", "Syria"=>"Syrian",
      "Taiwan"=>"Taiwanese", "Tajikistan"=>"Tajik", "Tanzania"=>"Tanzanian", "Thailand"=>"Thai", "Togo"=>"Togolese", "Trinidad & Tobago"=>"Trinidadian", "Tunisia"=>"Tunisian", "Turkey"=>"Turkish", "Turkmenistan"=>"Turkmen", "Tuvalu"=>"Tuvaluan",
      "Uganda"=>"Ugandan", "Ukraine"=>"Ukrainian", "United Arab Emirates"=>"UAE", "United Kingdom"=>"UK", "United States"=>"United States", "US" => "United States", "Uruguay"=>"Uruguayan", "Uzbekistan"=>"Uzbek",
      "Vanuatu"=>"Vanuatuan", "Venezuela"=>"Venezuelan", "Vietnam"=>"Vietnamese",
      "Wales"=>"Welsh", "Western Samoa"=>"Western Samoan",
      "Yemen"=>"Yemeni", "Yugoslavia"=>"Yugoslav",
      "Zaire"=>"Zaïrean", "Zambia"=>"Zambian", "Zimbabwe"=>"Zimbabwean"
    }
  end
  
  def self.full_name_state(state_name)
    states = self.full_name_states
    if states[state_name]
      return states[state_name]
    else
      return state_name
    end
  end

  def self.nationality(country_name)
    nationalities = self.nationalities

    if nationalities[country_name]
      return nationalities[country_name]
    else
      return country_name
    end
  end

  private
  def compile_speech_text_raw_value(arg, &speech_block)
    val = arg["raw"]
    if arg['speech_type']
      speech_block.call(val, arg['speech_type'])
    end
    val
  end
  
  def compile_speech_text_field_value(arg, doc, u, &speech_block)
    val = doc.document_field_values.where(:local_standard_document_field_id => arg["field_id"].to_i).first
    if val
      val.user_id = u.id  #To get the private key to decrypt incase of secure field
      val = val.field_value
      if arg["processor"]
        val = StandardDocumentField.send(arg["processor"].to_sym, val)
      end

      if arg["speech_type"]
        speech_block.call(val, arg['speech_type'])
      end
      val
    else
      ""
    end
  end

end
