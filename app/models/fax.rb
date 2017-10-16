class Fax < ActiveRecord::Base
  include AASM
  SOURCE='Fax'

  belongs_to :sender, class_name: 'User'
  belongs_to :document
  has_one :credit_transaction, class_name: 'UserCreditTransaction', as: :transactionable # Will not set dependent: destroy/nullify to maintain histories.

  validates :document_id, :status, :fax_number, :sender_id, :pages_count, presence: true
  validates :document_id, uniqueness: true
  validates :status, inclusion: { in: %w(ready sending sent failed) }

  scope :for_document, -> (document_id) { where(document_id: document_id) }

  aasm column: :status do
    state :ready, initial: true
    state :sending
    state :sent
    state :failed

    event :start_sending  do
      transitions from: [:ready, :failed], to: :sending
    end

    event :complete_sent, :after => [:revoke_docytbot_access, :complete_transaction, :generate_notification] do
      transitions from: [:sending], to: :sent
    end

    event :failure_sent, after: [:void_transaction, :generate_notification] do
      transitions from: [:sending], to: :failed
    end
  end

  def generate_notification
    return unless self.failed? || self.sent?

    notification = Notification.new
    notification.recipient = self.sender
    if self.sent?
      notification.message = "Fax submission completed for #{self.document.standard_document.name}."
    elsif self.failed?
      notification.message = "Fax submission failed for #{self.document.standard_document.name}."
    end
    notification.notifiable = self
    notification.notification_type = Notification.notification_types[:fax_updated]
    if notification.save!
      notification.deliver([:push_notification])
    end
  end

  def revoke_docytbot_access
    self.document.revoke_sharing(:with_user_id => nil)
  end

  def complete_transaction
    if self.credit_transaction
      self.credit_transaction.complete!
    end
  end

  def void_transaction
    if self.credit_transaction
      self.credit_transaction.fail!
    end
  end

  def enqueue_send_fax
    SendFaxJob.perform_later(self.id)
  end

end
