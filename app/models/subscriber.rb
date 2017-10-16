class Subscriber < ActiveRecord::Base
  validates :email, presence: true, uniqueness: true
  validates :email, format: { with: User::EMAIL_REGEX }
end
