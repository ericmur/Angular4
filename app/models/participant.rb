class Participant < ActiveRecord::Base
  belongs_to :workflow
  belongs_to :user
  has_many :workflow_standard_documents, as: :ownerable, dependent: :nullify

  validates :user_id, presence: true

  def avatar
    user.avatar
  end

  def full_name
    user.parsed_fullname
  end
end
