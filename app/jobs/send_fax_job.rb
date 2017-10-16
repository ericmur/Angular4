class SendFaxJob < ActiveJob::Base
  queue_as :send_fax

  def perform(fax_id)
    fax_service = FaxService.new(fax_id)
    fax_service.download_document_and_send_fax
  end

end
