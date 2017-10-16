class Api::DocytBot::V1::Filters::DateRangeFilter < Api::DocytBot::V1::Filters::BaseFilter
  def initialize(user, ctx)
    @user = user
    @from_date = normalize_date(ctx[:text], 'from')
    @to_date = normalize_date(ctx[:text], 'to')
    
    @ctx = ctx
    @pre_filter_docs_ids = ctx[:document_ids]
    @intent = ctx[:intent]
  end

  def call
    return @ctx if !exists_date?(@ctx[:text])
    Rails.logger.debug "[DocytBot] Processing filter: DateRangeFilter between #{@from_date.inspect} and #{@to_date.inspect}"
    docs_ids = []
    
    all_docs_hash = get_date_docs('date')
    Rails.logger.debug "[DocytBot] DateRangeFilter found docs with date type fields: #{all_docs_hash.keys.inspect}"
    all_docs_hash.each do |doc_id, date|
      date = Date.strptime(date, "%m/%d/%Y")
      if date_between(date, @from_date, @to_date)
        Rails.logger.debug "[DocytBot] DateRangeFilter found document in date range: #{doc_id}"
        docs_ids << doc_id
      else
        Rails.logger.debug "[DocytBot] DateRangeFilter did not find document, #{doc_id} date, #{date.inspect} in range"
      end
    end

    Rails.logger.debug "[DocytBot] Filtered Documents from DateRangeFilter: #{docs_ids.inspect}"
    @ctx[:document_ids] = docs_ids
    return @ctx
  end
end
