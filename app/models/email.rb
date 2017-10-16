class Email < ActiveRecord::Base
  SOURCE = 'ForwardedEmail'
  belongs_to :user
  belongs_to :standard_document
  belongs_to :business
  has_many :documents, :dependent => :nullify
  validates_presence_of :from_address, :to_addresses

  def upload_email_address
    to_addresses.split(',').select { |e| e.match('docyt.io') }.first
  end
end
