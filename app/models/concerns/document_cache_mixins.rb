require 'active_support/concern'

module DocumentCacheMixins
  extend ActiveSupport::Concern

  class_methods do
    def get_latest_cache_for_user(user)
      where(user_id: user.id).order(version: :asc).only(:version).last
    end

    def get_latest_cache_for_system
      order(version: :asc).only(:version).last
    end
  end



end