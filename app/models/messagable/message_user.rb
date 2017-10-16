module Messagable

  class MessageUser < ActiveRecord::Base
    belongs_to :receiver, polymorphic: true
    belongs_to :message

    validates :message_id, :uniqueness => { scope: [:receiver_id, :receiver_type], :message => "can only be associated with one receiver" }
  end

end
