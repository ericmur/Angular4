class RecalculateStorageCounterJob < ActiveJob::Base
  queue_as :default

  def perform(doc_id)
    doc = Document.where(:id => doc_id).first
    if doc
      doc.recalculate_storage_counter
    end
  end
end
