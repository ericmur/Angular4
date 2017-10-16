require 'active_support/concern'

module SerializerSymmetricKey
  extend ActiveSupport::Concern

  def symmetric_key
    symmetric_key = object.symmetric_keys.for_user_access(current_user.id).first
    SymmetricKeySerializer.new(symmetric_key, { :scope => scope, :root => false })
  end

end