class FieldValueSuggestion
  include Mongoid::Document
  WORDS_DISTANCE_THRESHOLD=0.89

  field :user_id, type: Integer
  field :standard_document_id, type: Integer
  field :data, type: Hash
  # { "Merchant": ["DOJ", "Avanti", "ULine", "Konica Minolta"], 
  #    "Item/Service": ["Inventory", "Maintenance", "Parts Purchase"]
  # }

  validates :data, presence: true
  validates :standard_document_id, presence: true

  index({ user_id: 1, standard_document_id: 1 })

  scope :for_user, -> (user_id) { where(user_id: user_id) }
  scope :for_system_and_user, -> (user_id) { any_of({ user_id: nil }, { user_id: user_id }) }
  scope :for_standard_document, -> (standard_document_id) { where(standard_document_id: standard_document_id) }

  def self.create_suggestion_for_field(user_id, standard_document_id, field_name, field_value)
    suggestion = FieldValueSuggestion.for_user(user_id).for_standard_document(standard_document_id).first
    if suggestion.present?
      suggestion.add_suggestion_for_field(field_name, field_value)
    else
      suggestion = FieldValueSuggestion.new({ user_id: user_id, standard_document_id: standard_document_id })
      field_name, field_value = FieldValueSuggestion.force_user_input_encoding(field_name, field_value)
      suggestion.data = { field_name => [field_value] }
      suggestion.save
    end
  end

  def self.suggested_by_system?(standard_document_id, field_name, field_value)
    suggestion = FieldValueSuggestion.where(user_id: nil).for_standard_document(standard_document_id).first
    return false if suggestion.blank?

    field_name, field_value = FieldValueSuggestion.force_user_input_encoding(field_name, field_value)
    suggestion.has_matched_suggestion?(field_name, field_value)
  end

  def has_matched_suggestion?(field_name, field_value)
    !top_matching_words(field_name, field_value).blank?
  end

  def top_matching_words(field_name, field_value)
    field_name, field_value = FieldValueSuggestion.force_user_input_encoding(field_name, field_value)
    return [] if data[field_name].blank?

    data[field_name].select do |suggestion_value|
      unless field_value.nil?
        RubyFish::Jaro.distance(suggestion_value.downcase, field_value.downcase) < WORDS_DISTANCE_THRESHOLD
      else
        false
      end
    end
  end

  def words_below_threshold(field_name, field_value)
    field_name, field_value = FieldValueSuggestion.force_user_input_encoding(field_name, field_value)
    return [] if data[field_name].blank?

    data[field_name].select do |suggestion_value|
      RubyFish::Jaro.distance(suggestion_value.downcase, field_value.downcase) < WORDS_DISTANCE_THRESHOLD
    end
  end

  def add_suggestion_for_field(field_name, field_value)
    #Save field object before downcasing field_name
    field_obj = StandardDocumentField.where(:name => field_name, :standard_document_id => self.standard_document_id).first
    
    field_name, field_value = FieldValueSuggestion.force_user_input_encoding(field_name, field_value)

    if data[field_name].blank?
      data[field_name] = [field_value]
      save
      return true
    end

    # Replace top matching words with new field value
    data[field_name] = words_below_threshold(field_name, field_value)
    if self.user_id.present?
      # Check if value already suggested by system
      unless FieldValueSuggestion.suggested_by_system?(standard_document_id, field_name, field_value)
        data[field_name] << field_value
      end
    else
      data[field_name] << field_value
    end
    
    distinct_values = DocumentFieldValue.joins(document: :symmetric_keys).where(symmetric_keys: { created_for_user_id: user_id }, documents: { standard_document_id: standard_document_id }).where(local_standard_document_field_id: field_obj.field_id).pluck("DISTINCT value")

    data[field_name] = data[field_name].select { |cached_value|
      # Check for equal value. If exists, they should be on suggestions.
      equal_value = distinct_values.find { |distinct_value| distinct_value.downcase == cached_value.downcase }
      if equal_value != nil
        equal_value
      else
        distinct_values.find { |distinct_value| RubyFish::Jaro.distance(distinct_value.downcase, cached_value.downcase) > WORDS_DISTANCE_THRESHOLD }
      end
    }

    save
  end

  def suggestions_for_field(field_name)
    field_name, _ = FieldValueSuggestion.force_user_input_encoding(field_name, nil)

    return [] if data[field_name].blank?
    return [] unless data[field_name].is_a?(Array)
    data[field_name]
  end

  def self.force_user_input_encoding(field_name, field_value)
    field_name = field_name.squish.force_encoding(Encoding::UTF_8).downcase
    field_value = field_value ? field_value.strip.force_encoding(Encoding::UTF_8) : nil

    return field_name, field_value
  end
end
