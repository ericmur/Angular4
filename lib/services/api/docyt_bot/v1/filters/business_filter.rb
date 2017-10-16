class Api::DocytBot::V1::Filters::BusinessFilter < Api::DocytBot::V1::Filters::BaseFilter
  def initialize(user, ctx)
    @user = user
    @ctx = ctx
    @pre_filter_docs_ids = ctx[:document_ids]
  end

  def call
    Rails.logger.debug "[DocytBot] Processing filter: BusinessFilter"
    bizs = @user.businesses.select { |biz|
      ::Api::DocytBot::V1::Matcher.new(@ctx[:text]).inclusion_score_for(cleanup(biz.name)).to_i == 1
    }

    return @ctx if bizs.empty?
    
    docs_ids = []
    if @pre_filter_docs_ids.blank?
      docs_ids = BusinessDocument.where(:business_id => bizs.map(&:id).pluck(:document_id))
      docs_ids = SymmetricKey.where(:document_id => docs_ids).for_user_access(@user.id).pluck(:document_id)
    else
      docs_ids = BusinessDocument.where(:business_id => bizs.map(&:id), :document_id => @pre_filter_docs_ids).pluck(:document_id)
      docs_ids = SymmetricKey.where(:document_id => docs_ids).for_user_access(@user.id).pluck(:document_id)
    end

    @ctx[:document_ids] = docs_ids
    Rails.logger.debug "[DocytBot] Filtered documents from BusinessFilter: #{docs_ids}"
    return @ctx
  end

  private
  def cleanup(biz_name)
    ['Inc', 'Incorporated', 'llc'].each do |ext|
      if biz_name.match(/\b#{ext}\b/i)
        return biz_name.gsub(/\b#{ext}\b/i,'')
      end
    end
    return biz_name
  end
end
