class CheckFaxesStatusJob < ActiveJob::Base
  queue_as :check_faxes_status

  def perform
    FaxService.search_sending_faxes_and_update_status
  end

end
