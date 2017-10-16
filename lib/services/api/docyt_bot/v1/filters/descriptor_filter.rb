class Api::DocytBot::V1::Filters::DescriptorFilter < Api::DocytBot::V1::Filters::BaseFilter
  def initialize(user, ctx)
    @user = user
    @ctx = ctx
    @pre_filter_docs_ids = ctx[:document_ids]
  end

  def call
    Rails.logger.debug "[DocytBot] Processing filter: DescriptorFilter"
    docs_ids = []
    docs = Document.where(:id => @pre_filter_docs_ids)
    matching_doc_n_gram_length = { }
    matching_doc_score = { }
    docs.each do |doc|
      next if doc.standard_document.nil?
      primary_descriptor_fields = doc.standard_document.standard_document_fields.where(:data_type => 'string')
      
      primary_descriptor_fields.each do |primary_descriptor_field|
        descriptor_field_value_objs = doc.document_field_values.where(:local_standard_document_field_id => primary_descriptor_field.field_id)
        descriptor_field_value_objs.map { |obj| obj.user_id = @user.id }

        matching_value_n_gram_length = { }
        matching_value_score = { }
        descriptor_field_value_objs = descriptor_field_value_objs.select { |f|
          val = f.field_value
          next if val.nil?
          if primary_descriptor_field.data_type == "state"
            val = StandardDocumentField.full_name_state(f.field_value)
          end

          if primary_descriptor_field.data_type == 'country'
            val = StandardDocumentField.nationality(f.field_value)
          end

          #Skip those keywords that were already used by DocumentNameFilter to filter documents.
          if @ctx[:document_name_matching_aliases]
            unless primary_descriptor_field.encryption
              Rails.logger.debug "[DocytBot] Checking if we need to skip filtering using these aliases in DescriptorFilter: #{@ctx[:document_name_matching_aliases].inspect} for #{val}"
            else
              Rails.logger.debug "[DocytBot] Checking if we need to skip filtering using these aliases in DescriptorFilter: #{@ctx[:document_name_matching_aliases].inspect}"
            end
            if @ctx[:document_name_matching_aliases].find { |doc_alias|
                ::Api::DocytBot::V1::Matcher.new(doc_alias).inclusion_score_for(val).to_i == 1 
              }
              unless primary_descriptor_field.encryption
                Rails.logger.debug "[DocytBot] Alias #{val} was used in DocumentNameFilter to filter documents. Skipping it in DescriptorFilter"
              else
                Rails.logger.debug "[DocytBot] An Alias was used in DocumentNameFilter to filter documents. Skipping it in DescriptorFilter"
              end
              next
            end
          end
          
          score = ::Api::DocytBot::V1::Matcher.new(@ctx[:text]).inclusion_score_for(val)
          if score > ::Api::DocytBot::V1::Matcher::DOC_FIELD_THRESHOLD_SCORE
            Rails.logger.debug "[DocytBot] Trying to apply DescriptorFilter using #{val}."
            if matching_value_n_gram_length[f].nil? or matching_value_n_gram_length[f] < n
              Rails.logger.debug "[DocytBot] Applying DescriptorFilter using #{val}."
              matching_value_n_gram_length[f] = val.split(" ")
              matching_value_score[f] = score
            else
              Rails.logger.debug "[DocytBot] Skip applying DescriptorFilter using #{val} as it is not the longest matching keyword. Better match available through other keywords."
            end
          end
            
          unless primary_descriptor_field.encryption
            Rails.logger.debug "[DocytBot] Longest matching keyword for #{val} is of length: #{matching_value_n_gram_length[f]}"
          end
          matching_value_n_gram_length[f]
        }
        
        if descriptor_field_value_objs.first
          matching_value_n_gram_length.each do |field_value_obj, n|
            score = matching_value_score[field_value_obj]
            if matching_doc_n_gram_length[field_value_obj.document_id].nil?
              matching_doc_n_gram_length[field_value_obj.document_id] = n
              matching_doc_score[field_value_obj.document_id] = score
            else
              #If there are multiple descriptor fields in a document, then we sum up the matches of multiple fields
              matching_doc_n_gram_length[field_value_obj.document_id] += n
              matching_doc_score[field_value_obj.document_id] += score
            end
          end
          
          descriptor_field_value_objs.each do |fv|
            docs_ids << fv.document_id unless docs_ids.include?(fv.document_id)
          end
        end
      end
    end
    
    unless docs_ids.blank?
      docs_ids.uniq!
      Rails.logger.debug "[DocytBot] Filtered Documents from DescriptorFilter prior to screening by max keywords matches: #{docs_ids.inspect}"
      
      docs_ids = find_max_n_gram_length_and_score_matches(docs_ids, matching_doc_n_gram_length, matching_doc_score)
      
      Rails.logger.debug "[DocytBot] Filtered Documents from DescriptorFilter after screening by max keywords matches: #{docs_ids.inspect}"
      @ctx[:document_ids] = docs_ids
    else
      Rails.logger.debug "[DocytBot] No descriptor specified in the query. Skipping DescriptorFilter."
    end
    return @ctx
  end

  private
  def find_max_n_gram_length_and_score_matches(docs_ids, matching_n_gram_lengths, matching_score)
    max_n_gram_length = (matching_n_gram_lengths.max_by { |k, v| v })[1]
    #First honor max_n_gram_length and then if there are multiple such matches with max length, then look at max_score among them to pick the top ones.
    doc_ids = (matching_n_gram_lengths.select { |k, v|
      v == max_n_gram_length
     }).keys

    doc_ids_hash = matching_score.select { |k, v| doc_ids.include?(k) }
    max_score = (doc_ids_hash.max_by { |k, v| v })[1]
    (matching_score.select { |k, v|
       v == max_score
     }).keys
  end
end
