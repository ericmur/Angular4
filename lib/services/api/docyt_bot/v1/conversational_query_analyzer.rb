class Api::DocytBot::V1::ConversationalQueryAnalyzer
  DOC_THRESHOLD_SCORE = 0.89
  DOC_FIELD_THRESHOLD_SCORE = 0.89
  NAME_THRESHOLD_SCORE = 0.89
  
  def initialize(sentence)
    @sentence = sentence
    @sentence_unpunct = @sentence.downcase.gsub(/'/,'')
  end

  ###############
  #show doc/value of field, show total, show avg, show max, show boolean
  ###############
  def predict_intent
    raise 'Not yet implemented'
  end
  
  ############
  #Add 1 to matching full_name, 0.5 to matching first name, 0.25 to matching
  #last name. When we say matching we mean it is over THRESHOLD score.
  ############
  def predict_owner(users)
    #users parameter is of the form: { '1' => "Sugam Pandey", '2' => "Tedi Braja", '3' => "Aibek Dzhakipov", '4' => "Vlad Vorobiov" }
    full_name_bias = 1.0
    first_name_bias = 0.5
    last_name_bias = 0.25
    scores_for_users = { }
    users.each do |id, name|
      name = cleanup(name)
      first_name = cleanup(first_name(name))
      last_name = cleanup(last_name(name))
      if name and (score = n_gram_matching_score(name)) > NAME_THRESHOLD_SCORE
        scores_for_users[id] = { :name => name, :score => score + full_name_bias }
      elsif first_name and (score = n_gram_matching_score(first_name)) > NAME_THRESHOLD_SCORE
        scores_for_users[id] = { :name => first_name, :score => score + first_name_bias }
      elsif last_name and (score = n_gram_matching_score(last_name)) > NAME_THRESHOLD_SCORE
        scores_for_users[id] = { :name => last_name, :score => score + last_name_bias }
      end
    end

    full_name_matches = scores_for_users.select { |k, v| v[:score] > full_name_bias + NAME_THRESHOLD_SCORE }
    if full_name_matches.count > 0
      full_name_matches = remove_approx_matches_if_accurate_found(full_name_matches)
      return full_name_matches.keys
    elsif
      first_name_matches = scores_for_users.select { |k, v| v[:score] > first_name_bias + NAME_THRESHOLD_SCORE }
      if first_name_matches.count > 0
        first_name_matches = remove_approx_matches_if_accurate_found(first_name_matches)
        return first_name_matches.keys
      else
        scores_for_users = remove_approx_matches_if_accurate_found(scores_for_users)
        return scores_for_users.select { |k, v| v[:score] > last_name_bias + NAME_THRESHOLD_SCORE }.keys
      end
    end
  end

  def predict_doc_type(docs_names)
    #doc_names parameter is of the form: { '1' => ['Drivers License'], '2' => ['Passport'] }
    scores_for_docs_names = { }
    docs_names.each do |id, doc_names|
      doc_name = doc_names.max { |doc_name1, doc_name2| n_gram_matching_score(doc_name1) <=> n_gram_matching_score(doc_name2) }
      scores_for_docs_names[id] = { :name => doc_name, :score => n_gram_matching_score(doc_name) }
    end

    best_match_docs_names = scores_for_docs_names.select { |k, v| v[:score] >= DOC_THRESHOLD_SCORE }
    best_match_doc_names = remove_approx_matches_if_accurate_found(best_match_doc_names)
    best_match_docs_names.keys
  end

  # doc_field_names = { '1' => ['License Number', 'License no', 'Drivers License Number'] }
  def predict_field_name(doc_fields_names)
    scores_for_doc_field_names = { }
    doc_fields_names.each do |id, doc_field_names|
      max_score = doc_field_names.map { |doc_field_name| n_gram_matching_score(doc_field_name) }.max
      doc_field_names = doc_field_names.select { |doc_field_name| n_gram_matching_score(doc_field_name) == max_score }
      longest_doc_field_name = doc_field_names.max { |doc_field_name| doc_field_name.length }
      scores_for_doc_field_names[id] = { :name => longest_doc_field_name, :score => n_gram_matching_score(longest_doc_field_name) }
    end

    best_match_doc_field_names = scores_for_doc_field_names.select { |k, v| v[:score] >= DOC_FIELD_THRESHOLD_SCORE }
    best_match_doc_field_names = remove_approx_matches_if_accurate_found(best_match_doc_field_names)
    best_match_doc_field_names.keys
  end

  ###################
  # Sample doc_fields parameter:
  # { '1' => { 'type' => 'string', 'field_name' => 'Merchant', 'value' => 'Konica Minolta' }, '2' => { 'type' => 'date', 'field_name' => 'Invoice Date', 'value' => '03/10/2016' } }
  #
  #
  # Conditions to check:
  # a) name/value condition
  # b) amount/currency in range condition
  # c) date condition, expiry_date condition, due_date condition
  # d) paid/unpaid boolean condition
  ##################
  def predict_condition(doc_fields)
    raise 'Not yet implemented'
  end

  def cleanup(txt)
    ::Api::DocytBot::V1::Matcher.new(nil).cleanup(txt)
  end

  private

  def remove_approx_matches_if_accurate_found(hsh)
    Rails.logger.info "Hsh: #{hsh.inspect}"
    filtered_matches = hsh.select { |id, value| value[:score].to_f == 1.0 }
    if filtered_matches.count > 1
      _, max_value_hash = filtered_matches.max_by { |id, value| value[:name].length }
      max_value = max_value_hash[:name].length
      Rails.logger.info "Filtered Matches: #{filtered_matches.inspect}"
      filtered_matches.select { |id, value| value[:name].length == max_value }
    else
      hsh
    end
  end
  
  def n_gram_matching_score(text)
    ::Api::DocytBot::V1::Matcher.new(@sentence).inclusion_score_for(text)
  end

  def first_name(name)
    if (ns = name.split()) and ns.first
      ns.first
    else
      nil
    end
  end

  def last_name(name)
    if (ns = name.split()) and ns.count > 1
      ns.last
    else
      nil
    end
  end

end
