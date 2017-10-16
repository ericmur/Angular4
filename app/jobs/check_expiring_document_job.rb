class CheckExpiringDocumentJob < ActiveJob::Base
  queue_as :scheduled

  def perform
    require 'slack_helper'
    SlackHelper.with_notifier("#docyt", "ExpiringDocumentJob", "scheduler") do
      Document.check_expiring_documents
    end
  end
end