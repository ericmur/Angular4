require 'rails_helper'

RSpec.describe SendNotificationJob, type: :job do
  let!(:job) { SendNotificationJob.new  }

  context '#perform' do
    it 'should call #search_and_send_unread_notifications once' do
      notification = double
      allow(NotificationService).to receive(:new).and_return(notification)
      allow_any_instance_of(NotificationService).to receive(:search_and_send_unread_notifications).and_return(true)

      expect(NotificationService).to receive(:new).once
      expect(notification).to receive(:search_and_send_unread_notifications).once
      job.perform
    end
  end

end
