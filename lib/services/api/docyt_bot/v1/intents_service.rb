require 'net/http'

class Api::DocytBot::V1::IntentsService
  GET_DOC_FIELD_INFO = "GetDocumentFieldInfo"
  GET_DOC_EXPIRATION_INFO = "GetDocumentExpirationInfo"
  GET_DOCS_LIST = "GetDocumentsList"
  GET_EXPIRING_DOCS_LIST = "GetExpiringDocumentsList"
  GET_EXPIRED_DOCS_LIST = "GetExpiredDocumentsList"
  GET_DUE_DOCS_LIST = "GetDueDocumentsList"
  GET_TOTAL_AMOUNT = "GetCurrencyDocumentsList"
  GET_PAST_DUE_DOCS_LIST = "GetPastDueDocumentsList"
  
  def initialize(user, session, opts = { })
    @user = user
    @text = opts[:text]
    @intent = opts[:intent]
    @slots = opts[:slots]
    @session = session
    @device_type = opts[:device_type]
    
    @filters_pipeline = { }
    @filters_pipeline[GET_DOC_EXPIRATION_INFO] = [
                                                  ::Api::DocytBot::V1::Filters::OwnerFilter,
                                                  ::Api::DocytBot::V1::Filters::BusinessFilter,
                                                  ::Api::DocytBot::V1::Filters::DocumentNameFilter,
                                                  ::Api::DocytBot::V1::Filters::DescriptorFilter,
                                                  ::Api::DocytBot::V1::Filters::ExpirationFieldFilter
                          ]
    @filters_pipeline[GET_DOC_FIELD_INFO] = [::Api::DocytBot::V1::Filters::OwnerFilter,
                                             ::Api::DocytBot::V1::Filters::BusinessFilter,
                                             ::Api::DocytBot::V1::Filters::DocumentNameFilter,
                                             ::Api::DocytBot::V1::Filters::DescriptorFilter,
                                             ::Api::DocytBot::V1::Filters::FieldNameFilter
                                            ]
    @filters_pipeline[GET_DOCS_LIST] = [::Api::DocytBot::V1::Filters::OwnerFilter,
                                        ::Api::DocytBot::V1::Filters::BusinessFilter,
                                        ::Api::DocytBot::V1::Filters::DocumentNameFilter,
                                        ::Api::DocytBot::V1::Filters::DescriptorFilter,
                                        ::Api::DocytBot::V1::Filters::DateRangeFilter,
                                        ::Api::DocytBot::V1::Filters::CurrencyRangeFilter
                                      ]
    @filters_pipeline[GET_EXPIRING_DOCS_LIST] = [::Api::DocytBot::V1::Filters::OwnerFilter,
                                                 ::Api::DocytBot::V1::Filters::BusinessFilter,
                                                 ::Api::DocytBot::V1::Filters::DocumentNameFilter,
                                                 ::Api::DocytBot::V1::Filters::DescriptorFilter,
                                                 ::Api::DocytBot::V1::Filters::ExpiringDateRangeFilter]
    @filters_pipeline[GET_EXPIRED_DOCS_LIST] = [::Api::DocytBot::V1::Filters::OwnerFilter,
                                                ::Api::DocytBot::V1::Filters::BusinessFilter,
                                                ::Api::DocytBot::V1::Filters::DocumentNameFilter,
                                                ::Api::DocytBot::V1::Filters::DescriptorFilter,
                                                ::Api::DocytBot::V1::Filters::ExpiredDateRangeFilter]
    @filters_pipeline[GET_DUE_DOCS_LIST] = [::Api::DocytBot::V1::Filters::OwnerFilter,
                                            ::Api::DocytBot::V1::Filters::BusinessFilter,
                                            ::Api::DocytBot::V1::Filters::DocumentNameFilter,
                                            ::Api::DocytBot::V1::Filters::DescriptorFilter,
                                            ::Api::DocytBot::V1::Filters::DueDateRangeFilter]
    @filters_pipeline[GET_PAST_DUE_DOCS_LIST] = [::Api::DocytBot::V1::Filters::OwnerFilter,
                                                 ::Api::DocytBot::V1::Filters::BusinessFilter,
                                                 ::Api::DocytBot::V1::Filters::DocumentNameFilter,
                                                 ::Api::DocytBot::V1::Filters::DescriptorFilter,
                                                 ::Api::DocytBot::V1::Filters::PastDueDateRangeFilter]
    @filters_pipeline[GET_TOTAL_AMOUNT] = [::Api::DocytBot::V1::Filters::OwnerFilter,
                                           ::Api::DocytBot::V1::Filters::BusinessFilter,
                                           ::Api::DocytBot::V1::Filters::ReceiptTypeFilter,
                                           ::Api::DocytBot::V1::Filters::DescriptorFilter,
                                           ::Api::DocytBot::V1::Filters::DateRangeFilter,
                                           ::Api::DocytBot::V1::Filters::CurrencyComputeFilter
                                          ]
  end

  def get_response
    ctx = process_intent
    ctx[:text] = @text
    threshold_score = 0.60
    old_intent = ctx[:intent]
    if ctx[:intent]
      Rails.logger.info "[DocytBot] Intent Detected from DocytBot: #{ctx[:intent]}"
      if ctx[:score] < threshold_score
        ctx[:intent] = fallback_intent_detector(ctx)
        old_intent = ctx[:intent] if ctx[:intent]
        Rails.logger.info "[DocytBot] Intent detected at score: #{ctx[:score]}. Re-detecting using fallback: #{ctx[:intent]}"
      end
      ctx = process_filters(ctx[:intent], ctx)
    end

    if ctx.nil?
      ctx = { :intent => no_results_fallback_intent_detector(old_intent), :text => @text }
      if ctx[:intent] != old_intent
        Rails.logger.info "[DocytBot] Intent failed to find any matches. Re-detecting using second fallback: #{ctx[:intent]}"
        ctx = process_filters(ctx[:intent], ctx)
      end
    end

    Rails.logger.info "[DocytBot] Final context being passed to Response object: #{ctx.inspect}"

    DocytBotUserQuestion.store_asked_question(@user, ctx)
    
    return ::Api::DocytBot::V1::Responses::Response.new(@user, @session, ctx, @device_type).generate
  end

  private
  
  def process_filters(intent, ctx_param)
    ctx = ctx_param
    @filters_pipeline[intent].each do |filter|
      ctx = filter.new(@user, ctx).call
      if ctx.nil?
        break
      end
    end
    return ctx
  end
  
  def process_intent
    if @device_type.downcase == ::Api::DocytBot::V1::Responses::BaseResponseModule::ALEXA.downcase
      #With Alexa we have the intent already
      { :intent => @intent, :slots => @slots }
    else
      #Get intent from DocytBot NLP service
      uri = IntentPredictor.uri
      uri.query = URI.encode_www_form({ :sentence => @text.downcase })
      resp = Net::HTTP.get_response(uri)

      if resp.kind_of? Net::HTTPSuccess
        intent_hash = JSON.parse(resp.body)
        return convert_to_sym(intent_hash)
      else
        Rails.logger.error "Error response from NLP Server: #{resp.inspect}"
        SlackHelper.ping({ channel: "#errors", username: "DocytBotNLPService", message: "Got error code: #{resp.code} for query: #{@text}" })
        return { :intent => nil }
      end
    end
  end

  
  def no_results_fallback_intent_detector(intent)
    if intent == GET_DOC_FIELD_INFO
      GET_DOCS_LIST
    elsif intent == GET_DOCS_LIST
      GET_DOC_FIELD_INFO
    else
      intent
    end
  end
  
  def fallback_intent_detector(ctx)
    if ctx[:text].match(/\bwhen\b.*\bexpiring\b/)
      ctx[:intent] = GET_DOC_EXPIRATION_INFO
    elsif ctx[:text].match(/\bexpired\b/)
      ctx[:intent] = GET_EXPIRED_DOCS_LIST
    elsif ctx[:text].match(/\bshow\b.*expiring\b/) or ctx[:text].match(/\bwhich\b.*\bexpiring\b/) or ctx[:text].match(/\blist\b.*\bexpiring\b/)
      ctx[:intent] = GET_EXPIRING_DOCS_LIST
    elsif ctx[:text].match(/\bdue\b/) and !ctx[:text].match(/\bpast due\b/)
      ctx[:intent] = GET_DUE_DOCS_LIST
    elsif ctx[:text].match(/\bpast due\b/)
      ctx[:intent] = GET_PAST_DUE_DOCS_LIST
    else
      if ctx[:intent] != GET_DOCS_LIST or ctx[:intent] != GET_DOC_FIELD_INFO
        GET_DOCS_LIST
      else
        ctx[:intent]
      end
    end
  end
  
  def convert_to_sym(input_hsh)
    input_hsh.inject({}){ |hsh,(k,v)|
      if v.class == Hash
        v = convert_to_sym(v)
      end
      hsh[k.to_sym] = v
      hsh
    }
  end
end

=begin

  def get_docs_response
    doc_objs = ::Api::DocytBot::V1::Intents::DocsIntentService.new(@user, @opts).call
    return build_docs_response(doc_objs)
  end

  def get_expiring_docs_response
    result = ::Api::DocytBot::V1::Intents::ExpiringDocsIntentService.new(@user, @opts).call
    users = result[:users]
    doc_objs = result[:doc_objs]
    return build_expiring_docs_response(doc_objs, users)
  end

  private
  def build_docs_response(doc_objs)
    ssml = nil
    if doc_objs.first
      ssml = "Here are the documents you requested. "
    else
      ssml = "I found no documents for you. "
    end
  end
  
  def build_expiring_docs_response(doc_objs, contacts = [])
    ssml = nil
    if doc_objs.first
      if @opts[:relationship_type] or @opts[:contact_name]
        first_names_str = get_first_names_string(contacts)
        unless first_names_str.blank?
          ssml = "Here is a list of the expiring documents for #{first_names_str} " + duration_str
        else
          ssml = "Here is a list of the expiring documents " + duration_str + ". "
        end
      else
        ssml = "Here is a list of your expiring documents " + duration_str + ". "
      end

      doc_objs.each do |doc_obj|
        doc = doc_obj.doc
        contact_first_name = nil
        if @opts[:relationship_type] or @opts[:contact_name]
          contact_first_name = get_one_matching_name(doc.document_owners, contacts)
        end
        
        doc_name = doc.primary_name ? doc.primary_name : doc.standard_document.name
        expiration_str = (doc_obj.expiration_date > Time.now) ? " is expiring on " : " is expired as of "
        expiration_date_str = ssml_date(doc_obj.expiration_date)
        if @opts[:relationship_type] or @opts[:contact_name]
          if !contact_first_name.blank?
            ssml += "#{contact_first_name}'s #{doc_name} #{expiration_str} #{expiration_date_str}"
          else
            ssml += "#{doc_name} #{expiration_str} #{expiration_date_str}. "
          end
        else
          ssml += "Your #{doc_name} #{expiration_str} #{expiration_date_str}. "
        end
      end
    else
      if @opts[:relationship_type] or @opts[:contact_name]
        first_names_str = get_first_names_string(contacts)
        unless first_names_str.blank?
          ssml = "There are no expiring documents for #{first_names_str} " + duration_str
        else
          ssml = "There are no expiring documents " + duration_str + ". "
        end
      else
        ssml = "You have no expiring documents " + duration_str + ". "
      end
    end

    return { "speech_output" => { "type" => "SSML", "speech" => "<speak>#{ssml}</speak>" } }
  end

  def duration_str
    dt = amazon_date_to_std_date(@opts[:expiring_date]).strftime("%Y%m%d") if @opts[:expiring_date]
    from_date = amazon_date_to_std_date(@opts[:from_expiring_date]).strftime("%Y%m%d") if @opts[:from_expiring_date]
    to_date = amazon_date_to_std_date(@opts[:to_expiring_date]).strftime("%Y%m%d") if @opts[:to_expiring_date]
    
    if @opts[:expiring_date]
      "as of #{ssml_date(dt)}"
    elsif @opts[:from_expiring_date] && @opts[:to_expiring_date]
      "between #{ssml_date(from_date)} and #{ssml_date(to_date)}"
    elsif @opts[:from_expiring_date]
      "after #{ssml_date(from_date)}"
    end
  end

  def amazon_date_to_std_date(amazon_date)
    if amazon_date == "PRESENT_REF"
      Time.now
    elsif amazon_date.match(/^\d{4}-W\d+$/)
      year = amazon_date.match(/^(\d{4})-W\d+$/) { $1 }
      week = amazon_date.match(/^\d{4}-W(\d+)$/) { $1 }
      Date.strptime("#{year}-#{week}", "%Y-%W") - 7.days #amazon week number format starts from 1 instead of 0
    elsif amazon_date.match(/^\d{4}-W\d+-WE$/)
      year = amazon_date.match(/^(\d{4})-W\d+-WE$/) { $1 }
      week = amazon_date.match(/^\d{4}-W(\d+)-WE$/) { $1 }
      Date.strptime("#{year}-#{week}", "%Y-%U")
    elsif amazon_date.match(/^\d{4}-\d+$/)
      Date.strptime(amazon_date, "%Y-%m")
    elsif amazon_date.match(/^\d{4}$/)
      Date.strptime(amazon_date, "%Y")
    elsif amazon_date.match(/^\d{4}-\d+-\d+$/)
      Date.strptime(amazon_date, "%Y-%m-%d")
    else
      Time.now
    end
  end

  def get_one_matching_name(doc_owners, requested_contacts)
    doc_owners.each do |doc_owner|
      if doc_owner.owner.class == GroupUser
        contact = requested_contacts.find { |c| c.class == GroupUser and c.id == doc_owner.owner_id }
      elsif doc_owner.owner.class == User
        contact = requested_contacts.find { |c| c.class == User and c.id == doc_owner.owner_id }
      elsif doc_owner.owner.class == Client
        contact = requested_contacts.find { |c| c.class == Client and c.id == doc_owner.owner_id }
      end

      if contact
        return contact.first_name
      end
    end
    return nil
  end

  def ssml_date(dt)
    dt_format = dt.strftime("%Y%m%d")
    "<say-as interpret-as='date'>#{dt_format}</say-as>"
  end

  
  
end
=end
