class Review < ActiveRecord::Base
  belongs_to :user

  validates :user_id, presence: true
  validates :user_id, uniqueness: true
  validates :last_version, presence: true

  def should_ask_review?(current_version)
    # For now lets avoid asking for review again if user has already reviewed any of the past versions already.
    # return Gem::Version.new(current_version) > Gem::Version.new(last_version)
    return false
  end
end
