class Api::DocytBot::V1::Matcher
  DOC_THRESHOLD_SCORE = 0.89
  DOC_FIELD_THRESHOLD_SCORE = 0.89
  NAME_THRESHOLD_SCORE = 0.89
  WORD_BOUNDARY_THRESHOLD_SCORE = 0.95
  
  def initialize(text)
    @text = text
  end

  # Jaro score for the best matching ngram in the text
  def inclusion_score_for(str)
    n_gram_str, n = join_underscore(str)
    score = 0
    @text.split.each_cons(n) do |arr|
      text_to_compare = cleanup(arr.join('_')).downcase
      if score < (new_score = RubyFish::Jaro.distance(text_to_compare, n_gram_str.downcase))
        score = new_score
      end
    end
    score
  end

  def match(str)
    RubyFish::Jaro.distance(@text.downcase, str.downcase)
  end

  def cleanup(txt)
    txt.gsub(/'s\b/,"")
  end

  private
  #Return joined text by underscore, n = number of strings joined
  def join_underscore(text)
    strs = text.split()
    
    [strs.join('_'), strs.count]
  end
end
