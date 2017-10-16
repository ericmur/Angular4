class CleanupUserLocationsJob < ActiveJob::Base
  queue_as :low

  def perform(user_id)
    user = User.find_by_id(user_id)
    user.cleanup_locations if user
  end
end
