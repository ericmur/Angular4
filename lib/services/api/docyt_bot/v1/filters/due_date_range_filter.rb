class Api::DocytBot::V1::Filters::DueDateRangeFilter < Api::DocytBot::V1::Filters::BaseFilter
  def initialize(user, ctx)
    @user = user
    @from_date = normalize_date(ctx[:text], 'from', Date.today - 30.days)
    @to_date = normalize_date(ctx[:text], 'to', Date.today + 30.days)
    
    @ctx = ctx
    @pre_filter_docs_ids = ctx[:document_ids]
    @intent = ctx[:intent]
  end

  def call
    return @ctx unless @intent == ::Api::DocytBot::V1::IntentsService::GET_DUE_DOCS_LIST
    if @to_date.nil?
      @to_date = Date.today + 30.days
    end
    if @from_date.nil?
      @from_date = Date.today - 30.days
    end
    docs_ids = []
    all_due_docs_hash = get_date_docs('due')
    all_due_docs_hash.each do |doc_id, due_date|
      due_date = Date.strptime(due_date, "%m/%d/%Y")
      if date_between(due_date, @from_date, @to_date)
        docs_ids << doc_id
      end
    end
    
    @ctx[:document_ids] = docs_ids
    return @ctx
  end

end
