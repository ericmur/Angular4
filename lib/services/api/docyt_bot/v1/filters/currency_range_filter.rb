class Api::DocytBot::V1::Filters::CurrencyRangeFilter < Api::DocytBot::V1::Filters::BaseFilter
  def initialize(user, ctx)
    @user = user
    @ctx = ctx
    @pre_filter_docs_ids = ctx[:document_ids]
    @intent = ctx[:intent]
  end

  def call
    return @ctx if !exists_currency?(@ctx[:text])
    docs_ids = []
    
    @over_currency = extract_currency(@ctx[:text], 'over')
    @under_currency = extract_currency(@ctx[:text], 'under')

    all_docs_hash = get_currency_docs('currency')
    all_docs_hash.each do |doc_id, currency|
      if currency_between(currency, @over_currency, @under_currency)
        docs_ids << doc_id
      end
    end

    @ctx[:document_ids] = docs_ids
    return @ctx
  end
end
