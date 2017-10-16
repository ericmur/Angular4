require 'aasm'

class UserContactList < ActiveRecord::Base
  CHUNK_SIZE = 50
  include AASM

  belongs_to :user
  has_many :user_contacts, dependent: :destroy

  aasm column: :state do
    state :pending, initial: true
    state :uploaded

    event :complete_upload do
      transitions from: [:pending, :uploaded], to: :uploaded
    end
  end

  def update_completion!(current_offset, limit, max)
    if current_offset > self.uploaded_offset.to_i
      update_column(:uploaded_offset, current_offset)
    end
    update_column(:max_entries, max)
    if (uploaded_offset + 1) * limit >= max_entries
      complete_upload!
    end
  end
end