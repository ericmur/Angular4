class Api::DocytBot::V1::Filters::BaseFilter
  MONTHS_REGEX = 'January|February|March|April|May|June|July|August|September|October|November|December|Jan|Feb|Mar|Apr|Jun|Jul|Aug|Sep|Oct|Nov|Dec'
  CURRENCY_REGEX = '\$([0-9]*\.[0-9]+|[0-9]+)|([0-9]*\.[0-9]+|[0-9]+) +dollar'
  def call
    raise 'Should be defined in sub class'
  end

  private
  def date_between(dt, from_dt, to_dt)
    if from_dt.nil?
      if to_dt.nil?
        return true
      else
        dt <= to_dt
      end
    else
      if to_dt.nil?
        dt >= from_dt
      else
        dt >= from_dt and dt <= to_dt
      end
    end
  end

  def exists_date?(date_str)
    date_str.match(/#{MONTHS_REGEX}/i) or date_str.match(/\bweek\b|\bmonth\b|\byear\b/i)
  end

  def extract_date_phrase(date_str, type)
    to_date_str = from_date_str = nil
    if date_str.match(/\bfrom\b(.+)\bto\b(.+)/)
      from_date_str = $1
      to_date_str = $2
    elsif date_str.match(/\bbetween\b(.+)\band\b(.+)/)
      from_date_str = $1
      to_date_str = $2
    elsif date_str.match(/\bfrom\b/)
      #get me .... from January
      from_date_str = to_date_str = date_str
    else
      to_date_str = date_str
    end
    if type.downcase == "to"
      to_date_str
    else
      from_date_str
    end
  end

  def normalize_date(date_str, type, default = nil)
    return nil if date_str.nil?

    date_str = extract_date_phrase(date_str, type)
    return nil if date_str.nil?
    
    if dt = get_date_for_phrase(date_str, type, default)
      return dt
    else
      day = extract_day(date_str, type, default)
      month = extract_month(date_str, type, default)
      year = extract_year(date_str, type, default)

      year = Date.today.year if year.nil?
      if month.nil?
        if type == 'from'
          month = 1
        else
          month = 12
        end
      end

      if day.nil?
        if type == 'from'
          day = 1
        else
          day = Date.civil(year.to_i, month.to_i, -1).day
        end
      end

      Date.strptime("#{year}-#{month}-#{day}", "%Y-%m-%d")
    end
  end

  def extract_day(date_str, type, default)
    d = date_str.match(/\b[123][0-9]\b/)
    if d
      d[0]
    else
      nil
    end
  end

  def extract_month(date_str, type, default)
    m = date_str.match(/#{MONTHS_REGEX}/i)
    if m
      month_name = m[0]
      if (n = Date::MONTHNAMES.index(month_name.capitalize)).nil?
        Date::ABBR_MONTHNAMES.index(month_name.capitalize)
      else
        n
      end
    else
      nil
    end
  end

  def extract_year(date_str, type, default)
    y = date_str.match(/\b\d{4}\b/)
    if y
      y[0]
    else
      nil
    end
  end

  def get_date_for_phrase(str, type, default = nil)
    n = 'one|two|three|four|five|six|seven|eight|nine|\d+'
    case str
    when /today/
      Date.today
    when /tomorrow/
      Date.tomorrow
    when /this week/
      type == 'from' ? Date.today.monday : Date.today.saturday
    when /this month/
      type == 'from' ? Date.today.beginning_of_month : Date.today.end_of_month
    when /this year/
      type == 'from' ? Date.today.beginning_of_year : Date.today.end_of_year
    when /next week/
      type == 'from' ? (Date.today.monday + 7.days) : (Date.today.saturday + 7.days)
    when /next (#{n}) week/, /in (#{n}) week/
      match = $1
      if match.match(/^\d+$/)
        n = match.to_i
      else
        n = convert_word_to_num(match)
      end
      type == 'from' ? (Date.today.monday + n.weeks) : (Date.today.saturday + n.weeks)
    when /next month/
      type == 'from' ? (Date.today.monday + 1.month) : (Date.today.saturday + 1.month)
    when /next (#{n}) month/, /in (#{n}) month/
      match = $1
      if match.match(/^\d+$/)
        n = match.to_i
      else
        n = convert_word_to_num(match)
      end
      type == 'from' ? (Date.today.beginning_of_month + n.months) : (Date.today.end_of_month + n.months)
    when /last week/
      type == 'from' ? Date.today.monday.last_week : Date.today.saturday.last_week
    when /last (#{n}) week/
      match = $1
      if match.match(/^\d+$/)
        n = match.to_i
      else
        n = convert_word_to_num(match)
      end
      type == 'from' ? (Date.today.monday - n.weeks) : (Date.today.saturday - n.weeks)
    when /last month/
      type == 'from' ? Date.today.last_month.beginning_of_month : Date.today.last_month.end_of_month
    when /last (#{n}) month/
      match = $1
      if match.match(/^\d+$/)
        n = match.to_i
      else
        n = convert_word_to_num(match)
      end
      type == 'from' ? (Date.today.beginning_of_month - n.months) : (Date.today.end_of_month  - n.months)
    when /next year/
      type == 'from' ? (Date.today.beginning_of_year + 1.year) : (Date.today.end_of_year + 1.year)
    when /next (#{n}) year/, /in (#{n}) year/
      match = $1
      if match.match(/^\d+$/)
        n = match.to_i
      else
        n = convert_word_to_num(match)
      end
      type == 'from' ? (Date.today.beginning_of_year + n.years) : (Date.today.end_of_year + n.years)
    when /last year/
      type == 'from' ? Date.today.last_year.beginning_of_year : Date.today.last_year.end_of_year
    when /last (#{n}) year/
      match = $1
      if match.match(/^\d+$/)
        n = match.to_i
      else
        n = convert_word_to_num(match)
      end
      type == 'from' ? (Date.today.beginning_of_year - n.years) : (Date.today.end_of_year  - n.years)
    else
      default ? default : nil
    end
  end

  def convert_word_to_num(n_str)
    case n_str.downcase
    when /one/
      1
    when /two/
      2
    when /three/
      3
    when /four/
      4
    when /five/
      5
    when /six/
      6
    when /seven/
      7
    when /eight/
      8
    when /nine/
      9
    else
      20 #Make it a large number so everything is included
    end
  end

  def get_date_docs(type)
    if type == 'due'
      data_type = 'due_date'
    elsif type == 'expiry'
      data_type = 'expiry_date'
    else
      data_type = 'date'
    end
    hsh = { }
    @pre_filter_docs_ids.each do |doc_id|
      doc = Document.find(doc_id)
      next if doc.standard_document.nil?
      fields = doc.standard_document.standard_document_fields.where("data_type = ?", data_type).select(:id, :field_id)
      fields.each do |field|
        field_val_obj = doc.document_field_values.where(:local_standard_document_field_id => field.field_id).first
        next if field_val_obj.nil? or !field_val_obj.document.accessible_by_me?(@user)
        
        field_val_obj.user_id = @user.id
        
        hsh[doc_id] = field_val_obj.field_value
      end
    end
    hsh
  end

  #Below is using for Currency Range Filter

  def currency_between(ccy, over_ccy, under_ccy)
    if over_ccy.nil?
      if under_ccy.nil?
        return true
      else
        ccy <= under_ccy
      end
    else
      if under_ccy.nil?
        ccy >= over_ccy
      else
        ccy >= over_ccy and ccy <= under_ccy
      end
    end
  end

  def get_currency_docs(type)
    data_type = type
    hsh = { }
    @pre_filter_docs_ids.each do |doc_id|
      doc = Document.find(doc_id)
      next if doc.standard_document.nil?
      fields = doc.standard_document.standard_document_fields.where("data_type = ?", data_type).select(:id, :field_id)
      fields.each do |field|
        field_val_obj = doc.document_field_values.where(:local_standard_document_field_id => field.field_id).first
        next if field_val_obj.nil? or !field_val_obj.document.accessible_by_me?(@user)
        
        field_val_obj.user_id = @user.id
        
        hsh[doc_id] = field_val_obj.field_value
      end
    end
    hsh
  end

  def exists_currency?(ccy_str)
    return nil if ccy_str.nil?
    ccy_str.match(/#{CURRENCY_REGEX}/i)
  end

  def extract_currency(ccy_str, type)
    under_ccy_str = over_ccy_str = nil
    if ccy_str.match(/\bfrom\b(.+)\bto\b(.+)/) and exists_currency?($1) and exists_currency?($2)
      over_ccy_str = $1
      under_ccy_str = $2
    elsif ccy_str.match(/\bbetween\b(.+)\band\b(.+)/) and exists_currency?($1) and exists_currency?($2)
      over_ccy_str = $1
      under_ccy_str = $2
    elsif ccy_str.match(/\bover\b +(.+)\b/) or ccy_str.match(/\bmore than\b +(.+)\b/)
      over_ccy_str = $1
    elsif ccy_str.match(/\bunder\b +(.+)\b/) or ccy_str.match(/\bless than\b +(.+)\b/)
      under_ccy_str = $1
    end
    if type.downcase == "under"
      exists_currency?(under_ccy_str) ? under_ccy_str.scan(/[-+]?([0-9]*\.[0-9]+|[0-9]+)/).first[0] : nil
    else
      exists_currency?(over_ccy_str) ? over_ccy_str.scan(/[-+]?([0-9]*\.[0-9]+|[0-9]+)/).first[0] : nil
    end
  end
end
