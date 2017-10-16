module Encryption

  # PGP is Asymmetric encryption (with private/public keys). Should only be used to encrypt symmetric keys, which should then be used to encrypt data. Using PGP encryption for actual data will be very slow.
  #Usage: Note 'Passw0rd' is a sample password
  #  To create a new key and encrypt the data:
  #
  #    asymmetric_encryptor = Encryption::Pgp.new({:password => 'Passw0rd'})
  #    encrypted_data = asymmetric_encryptor.encrypt(data)
  #    save_into_db(encrypted_data, asymmetric_encryptor.public_key, asymmetric_encryptor.private_key_secure)
  #
  #
  #  To use an existing key (public_key_pem) and encrypt the data:
  #
  #    asymmetric_encryptor = Encryption::Pgp.new({:public_key => public_key_pem})
  #    encrypted_data = asymmetric_encryptor.encrypt(data)
  #    save_into_s3(encrypted_data)
  #
  #
  #  To use an existing key (private_key_pem) and decrypt the data:
  #
  #    symmetric_encryptor = Encryption::Pgp.new({:password => 'Passw0rd', :private_key => private_key_pem})
  #    data = symmetric_encryptor.decrypt(encrypted_data)
  #    use_data(data)
  #
  class Pgp
    KEY_SIZE = 2048
    attr_accessor :unencrypted_private_key, :public_key, :private_key

    def initialize(args = { })
      size = args[:size].blank? ? KEY_SIZE : args[:size]
      password = args[:password].blank? ? nil : args[:password]
      private_key = args[:private_key].blank? ? nil : args[:private_key]
      public_key = args[:public_key].blank? ? nil : args[:public_key]

      if private_key
        fail 'No password provided with private key' if password.blank?
        @key = OpenSSL::PKey::RSA.new private_key, password
        @private_key = get_encrypted_private_key(password)
      elsif public_key
        @key = OpenSSL::PKey::RSA.new public_key
      else
        fail 'No password provided to create keys' if password.nil?
        @key = OpenSSL::PKey::RSA.new size
        @private_key = get_encrypted_private_key(password)
      end

      @public_key = @key.public_key.to_pem
      @unencrypted_private_key = @key.to_pem
    end

    def encrypt(data)
      binary_encrypted_data = @key.public_encrypt data
      Base64.encode64(binary_encrypted_data) #Convert binary to text so we can save in DB.
    end

    def decrypt(binary_encrypted_data)
      encrypted_data = Base64.decode64(binary_encrypted_data)
      @key.private_decrypt(encrypted_data) #Convert binary to text so we can save in DB.
    end

    private
    def get_cipher
      OpenSSL::Cipher.new 'AES-128-CBC'
    end

    def get_encrypted_private_key(password)
      @key.export get_cipher, password
    end
  end


  #AES is symmetric key encryption. Used to encrypt the actual data
  #Usage:
  #  To create a new key and encrypt the data:
  #
  #    symmetric_encryptor = Encryption::Aes.new
  #    encrypted_data = symmetric_encryptor.encrypt(data)
  #    save_into_db(encrypted_data, symmetric_encryptor.key, symmetric_encryptor.iv)
  #
  #
  #  To use an existing key and encrypt the data:
  #    symmetric_encryptor = Encryption::Aes.new({:key => key, :iv => iv})
  #    encrypted_data = symmetric_encryptor.encrypt(data)
  #    save_into_db(encrypted_data, symmetric_encryptor.key, symmetric_encryptor.iv)
  #
  #
  #  To use an existing key and decrypt the data:
  #    symmetric_encryptor = Encryption::Aes.new({:key => key, :iv => iv})
  #    data = symmetric_encryptor.decrypt(encrypted_data)
  #    send_to_user(data)
  #
  # Note that data passed in should be binary data. If you are reading a file, do
  # this for instance to read in as binary data:
  #  data = File.open(file_path, 'rb') { |f| f.read }
  class Aes
    attr_accessor :iv, :key

    def initialize(args = { })
      @cipher = OpenSSL::Cipher::AES256.new(:CBC)
      unless args[:key].blank? and args[:iv].blank?
        fail "Both Initialization Vector and key should be provided" if args[:iv].blank? or args[:key].blank?
        @key = args[:key]
        @iv = args[:iv]
      else
        @cipher.encrypt #Init-ing is necessary before calling random_key and random_iv
        @key = @cipher.random_key
        @iv = @cipher.random_iv
      end
    end

    def encrypt(data)
      fail "Key and IV should be initialized before calling encrypt" if (@key.blank? or @iv.blank?)
      @cipher.encrypt
      @cipher.key = @key
      @cipher.iv = @iv

      encrypted_data = @cipher.update(data)
      encrypted_data << @cipher.final
      encrypted_data
    end

    def decrypt(encrypted_data)
      fail "Key and IV should be initialized before calling decrypt" if (@key.blank? or @iv.blank?)
      @cipher.decrypt
      @cipher.key = @key
      @cipher.iv = @iv

      data = @cipher.update(encrypted_data)
      data << @cipher.final
      data
    end
  end

  class MD5Digest
    def initialize
      @md5 = OpenSSL::Digest::MD5.new
    end

    def digest(data)
      @md5.reset
      @md5.digest(data)
    end

    def digest_base64(data)
      data_digest = digest(data)
      Base64.encode64(data_digest)
    end

    def file_digest_base64(path)
      data_digest = digest(File.read(path))
      Base64.encode64(data_digest).chomp
    end

    def file_hexdigest(path)
      @md5.hexdigest(File.read(path))
    end

  end
end
