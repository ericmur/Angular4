require 'aasm'

class Avatar < ActiveRecord::Base
  include AASM
  belongs_to :avatarable, polymorphic: true

  after_destroy :remove_avatar

  aasm column: :state do
    state :pending, :initial => true
    state :uploaded

    event :complete_upload do
      transitions from: [:pending], to: :uploaded
    end
  end

  private

  def remove_avatar
    DeleteS3ObjectJob.perform_later(s3_object_key) unless self.s3_object_key.blank?
  end

end
