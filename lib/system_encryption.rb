require 'encryption'

class SystemEncryption
  def initialize(opts = { })
    pgp = Encryption::Pgp.new({ :password => Rails.startup_password_hash, :private_key => Rails.private_key })
    if opts[:encryption_type] == 'pgp'
      @encryption = pgp
    else
      key = pgp.decrypt(Base64.decode64(Rails.symmetric_key))
      iv = pgp.decrypt(Base64.decode64(Rails.symmetric_iv))
      @encryption = Encryption::Aes.new({ :key => key, :iv => iv})
    end
  end
  
  def encrypt(data, opts = { })
    encrypted_data = @encryption.encrypt(data)
    if opts[:encode_base64]
      Base64.encode64(encrypted_data)
    else
      encrypted_data
    end
  end

  def decrypt(encrypted_data, opts = { })
    if opts[:base64_encoded]
      decoded_encrypted_data = Base64.decode64(encrypted_data)
    else
      decoded_encrypted_data = encrypted_data
    end
    @encryption.decrypt(decoded_encrypted_data)
  end
end
