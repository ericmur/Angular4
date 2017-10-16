class PageUploadCompletionJob < ActiveJob::Base
  queue_as :default

  def perform(page_id, user_id)
    page = Page.find_by_id(page_id)
    user = User.find_by_id(user_id)
    if page && user && page.uploaded?
      page.document.enqueue_create_notification_for_completed_page(user, page)
    end
  end
end
