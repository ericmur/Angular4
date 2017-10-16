class Api::Categorization::V1::DocytBotCategorizationsController < Api::Categorization::V1::ApiController
  def update_document_type
    @document = Document.find_by_id(params[:document_id])
    predictions = params[:predictions]
    if @document
      if !predictions.blank? and predictions.first
        suggested_std_id = best_prediction(predictions)
        if suggested_std_id
          @document.suggested_standard_document_id = suggested_std_id
          @document.suggested_at = Time.now
          @document.save!

          @document.revoke_sharing(:with_user_id => nil)
        else
          #No document type detected found
          @document.destroy if @document.from_cloud_scan?
        end
      else
        #No document type detected found
        @document.destroy if @document.from_cloud_scan?
      end

      if @document.cloud_service_folder.documents_to_auto_categorize.count == 0 and @document.cloud_service_folder.documents_auto_categorized.count > 0
        NotifyCategorizationCompleteJob.perform_later(@document.cloud_service_folder_id)
      end
    end

    respond_to do |format|
      format.json { render nothing: true, status: :ok }
    end
  end

  private
  def best_prediction(predictions)
    image_primary_threshold = 50
    image_secondary_threshold = 0
    keyword_primary_threshold = 90
    keyword_secondary_threshold = 50
    Rails.logger.info "Predictions: #{predictions.inspect}"
    max_image_standard_doc_hash = (predictions['image'] ? predictions['image'] : []).max { |a, b|
      a["score"].to_i <=> b["score"].to_i
    }

    max_keywords_standard_doc_hash = (predictions['keywords'] ? predictions['keywords'] : []).max { |a, b|
      a["score"].to_i <=> b["score"].to_i
    }

    #First categorize based on keywords model's score.
    #If keywords model's prediction is not over threshold then check if images model's score is over threshold.
    if max_keywords_standard_doc_hash and max_keywords_standard_doc_hash["score"].to_i > keyword_primary_threshold
      image_standard_doc_hash = (predictions['image'] ? predictions['image'] : []).find { |prediction| prediction['id'].to_i == max_keywords_standard_doc_hash["id"].to_i }
      if image_standard_doc_hash
        if image_standard_doc_hash["score"].to_i > image_secondary_threshold
          return image_standard_doc_hash["id"].to_i
        else
          return nil
        end
      else
        return max_keywords_standard_doc_hash["id"].to_i
      end
    elsif max_image_standard_doc_hash and max_image_standard_doc_hash["score"].to_i > image_primary_threshold
      keywords_standard_doc_hash = (predictions["keywords"] ? predictions["keywords"] : []).find { |prediction| prediction["id"].to_i == max_image_standard_doc_hash["id"].to_i }
      if keywords_standard_doc_hash
        if keywords_standard_doc_hash["score"].to_i > keyword_secondary_threshold
          return keywords_standard_doc_hash["id"].to_i
        else
          return nil
        end
      else
        return max_image_standard_doc_hash["id"].to_i
      end
    else
      return nil
    end
  end
end
