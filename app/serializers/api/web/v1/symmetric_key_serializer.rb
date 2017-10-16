class Api::Web::V1::SymmetricKeySerializer < ActiveModel::Serializer
  attributes :id, :created_for_user_id, :key, :key_md5

  def key
    if object.created_for_user_id == scope.id
      #Decrypt the key
      Base64.encode64(object.decrypt_key)
    else
      raise "Key requested for another user: #{self.created_for_user_id} by #{self.scope.id}"
    end
  end

  def key_md5
    @md5 = Encryption::MD5Digest.new
    @md5.digest_base64(object.decrypt_key)
  end
end
