class NotifyDuration < ActiveRecord::Base
  NONE = 0
  EXPIRING = 1
  EXPIRED = 2

  DEFAULT_EXPIRY_NOTIFY_DURATIONS = [
    { amount: 1, unit: "day" },
    { amount: 2, unit: "weeks" },
    { amount: 2, unit: "months" },
    { amount: 4, unit: "months" }
  ]

  DEFAULT_DUE_NOTIFY_DURATIONS = [
    { amount: 1, unit: "day" },
    { amount: 10, unit: "days" }
  ]

  belongs_to :base_document_field, :foreign_key => 'standard_document_field_id'

  # calculated date
  attr_accessor :scheduled_date
end
