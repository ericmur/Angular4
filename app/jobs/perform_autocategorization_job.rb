class PerformAutocategorizationJob < ActiveJob::Base
  queue_as :default

  def perform(document_id)
    document = Document.find_by_id(document_id)
    CategorizationService.new(document).call
  end
end
