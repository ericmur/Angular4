class Api::DocytBot::V1::Filters::DocumentNameFilter < Api::DocytBot::V1::Filters::BaseFilter
  def initialize(user, ctx)
    @user = user
    @ctx = ctx
    @intent = ctx[:intent]
    @pre_filter_docs_ids = ctx[:document_ids]
  end

  def call
    Rails.logger.debug "[DocytBot] Processing filter: DocumentNameFilter"
    document_ids = []
    document_aliases = []
    find_filtered_document_ids_by_document_name { |doc_aliases, doc|
      if (matching_doc_aliases = doc_aliases.select { |doc_alias| ::Api::DocytBot::V1::Matcher.new(@ctx[:text]).inclusion_score_for(doc_alias) > ::Api::DocytBot::V1::Matcher::DOC_THRESHOLD_SCORE }).first
        if !password_document_requested? and password_document?(doc)
          Rails.logger.debug "[DocytBot] Password document matched: #{doc.id} but password document was not requested"
          next
        end

        if password_document_requested? and !password_document?(doc)
          Rails.logger.debug "[DocytBot] Password document was requested but non-password document matched: #{doc.id}"
          next
        end
        
        document_ids << doc.id
        matching_doc_aliases.each do |doc_alias|
          document_aliases << doc_alias.downcase unless document_aliases.include?(doc_alias.downcase)
        end
      end
    }

    if document_ids.blank?
      if doc_name_present?
        Rails.logger.debug "[DocytBot] No documents from previous filters contain the document name requested by the user."
        @ctx[:document_ids] = []
      else
        Rails.logger.debug "[DocytBot] No document name specified in the query. Skipping DocumentNameFilter."
      end
    else
      Rails.logger.debug "[DocytBot] Filtered documents after applying DocumentNameFilter: #{document_ids.inspect}"
      @ctx[:document_ids] = document_ids
      Rails.logger.debug "[DocytBot] Aliases used for filtering in DocumentNameFilter: #{document_aliases.inspect}"
      @ctx[:document_name_matching_aliases] = document_aliases #We save this in context because DescriptorFilter will use this array to ensure it matches descriptors from the query after excluding these values
    end
    return @ctx
  end

  private

  def password_document?(doc)
    doc.standard_document.standard_folder.password_folder?
  end

  def password_document_requested?
    threshold = ::Api::DocytBot::V1::Matcher::WORD_BOUNDARY_THRESHOLD_SCORE
    (::Api::DocytBot::V1::Matcher.new(@ctx[:text]).inclusion_score_for("password").to_i >= threshold or
    ::Api::DocytBot::V1::Matcher.new(@ctx[:text]).inclusion_score_for("passwords").to_i >= threshold or
    ::Api::DocytBot::V1::Matcher.new(@ctx[:text]).inclusion_score_for("account number").to_i >= threshold or
    ::Api::DocytBot::V1::Matcher.new(@ctx[:text]).inclusion_score_for("account numbers").to_i >= threshold)
  end
  
  def find_filtered_document_ids_by_document_name(&block)
    Document.where(:id => @pre_filter_docs_ids).each do |doc|
      next if doc.standard_document.nil?
      doc_aliases = [doc.standard_document.name] + doc.standard_document.aliases.map(&:name)
      block.call(doc_aliases, doc)
    end
  end

  def doc_name_present?
    (Alias.where(:aliasable_type => 'StandardBaseDocument').pluck(:name) + StandardDocument.only_system.pluck(:name)).find { |name|
      ::Api::DocytBot::V1::Matcher.new(@ctx[:text]).inclusion_score_for(name) > ::Api::DocytBot::V1::Matcher::DOC_THRESHOLD_SCORE
    }
  end
end
