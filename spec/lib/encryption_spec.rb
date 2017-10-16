require 'rails_helper'
require 'spec_helper'
require 'encryption'

describe Encryption do 
  describe Encryption::Pgp do 
    it 'creates both pubic and private keys when password is provided' do 
      ecrypt = Encryption::Pgp.new({ :password => 'test123'})
      expect(ecrypt.private_key).not_to be(nil)
      expect(ecrypt.private_key.strip).not_to eq('')

      expect(ecrypt.public_key).not_to be(nil)
      expect(ecrypt.private_key.strip).not_to eq('')
    end

    it 'throws an error for creating keys when no password is provided' do 
      expect { 
      ecrypt = Encryption::Pgp.new
      }.to raise_error(RuntimeError, /no password/i)
    end

    it 'loads both private key and public key successfully when password is provided' do 
      private_key_pem = File.read('spec/data/id_rsa.test.vayuum.pem')
      public_key_pem = File.read('spec/data/id_rsa.test.vayuum.public.pem')
      ecrypt = Encryption::Pgp.new({ :private_key => private_key_pem, :password => 'test123'})
      
      expect(ecrypt.public_key).to eq(public_key_pem)
      expect(ecrypt.unencrypted_private_key).to_not eq(nil)
    end

    it 'decrypts the private key correctly when correct password is provided and it can be encrypted with a new password' do
      private_key_pem = File.read('spec/data/id_rsa.test.vayuum.pem')
      public_key_pem = File.read('spec/data/id_rsa.test.vayuum.public.pem')
      ecrypt = Encryption::Pgp.new({ :private_key => private_key_pem, :password => 'test123'})      
      expect(ecrypt.unencrypted_private_key).to_not eq(nil)

      new_ecrypt = Encryption::Pgp.new({ :private_key => ecrypt.unencrypted_private_key, :password => 'test12345' })
      expect(new_ecrypt.unencrypted_private_key).to eq(ecrypt.unencrypted_private_key)
      expect(new_ecrypt.private_key).to_not eq(ecrypt.unencrypted_private_key)

      new_ecrypt_2 = Encryption::Pgp.new({ :private_key => new_ecrypt.private_key, :password => 'test12345' })
      expect(new_ecrypt_2.unencrypted_private_key).to eq(new_ecrypt.unencrypted_private_key)
    end
    
    it 'loads public key but no private key when only public key is provided' do 
      public_key_pem = File.read('spec/data/id_rsa.test.vayuum.public.pem')
      ecrypt = Encryption::Pgp.new({ :public_key => public_key_pem, :password => 'test123'})
      expect(ecrypt.public_key).to eq(public_key_pem)
      expect(ecrypt.private_key).to equal(nil)
    end

    it 'throws an error to load private key when no password is provided' do 
      private_key_pem = File.read('spec/data/id_rsa.test.vayuum.pem')
      expect { 
        ecrypt = Encryption::Pgp.new({ :private_key => private_key_pem })
      }.to raise_error(RuntimeError, /no password/i)
    end

    it 'encrypts data successfully using public key which can be decrypted using the corresponding private key' do 
      symmetric_key_1 = 'symmetric key 1'
      ecrypt = Encryption::Pgp.new({ :password => 'test123' })
      encrypted_symmetric_key = ecrypt.encrypt(symmetric_key_1)
      expect(encrypted_symmetric_key).not_to eq(symmetric_key_1)
      symmetric_key = ecrypt.decrypt(encrypted_symmetric_key)
      expect(symmetric_key).to eq(symmetric_key_1)
    end

    it 'encrypts data successfuly using public key which cannot be decrypted using any other private key' do 
      symmetric_key_1 = 'symmetric key 1'
      symmetric_key_2 = 'symmetric key 2'
      ecrypt1 = Encryption::Pgp.new({ :password => 'test123' })
      ecrypt2 = Encryption::Pgp.new({ :password => 'test123' }) #Same password should not matter, its still a new key set
      encrypted_symmetric_key_1 = ecrypt1.encrypt(symmetric_key_1)
      expect(encrypted_symmetric_key_1).not_to eq(symmetric_key_1)
      expect { 
        symmetric_key_decrypted = ecrypt2.decrypt(encrypted_symmetric_key_1)
      }.to raise_error(OpenSSL::PKey::RSAError)
    end
  end

  describe Encryption::Aes do 
    it 'creates the IV and key successfully' do 
      ecrypt = Encryption::Aes.new
      expect(ecrypt.iv).not_to be(nil)
      expect(ecrypt.iv.strip).not_to eq('')

      expect(ecrypt.key).not_to be(nil)
      expect(ecrypt.iv.strip).not_to eq('')
    end

    it 'throws an error when key is provided without IV' do 
      expect { 
        ecrypt = Encryption::Aes.new(:key => 'asdf234asdf')
      }.to raise_error(RuntimeError)
      
    end

    it 'throw an error when IV is provided without key' do 
      expect { 
        ecrypt = Encryption::Aes.new(:iv => 'asdfsfqweqwe134123')
      }.to raise_error(RuntimeError)
    end

    it 'loads the key and IV successfully when they are provided' do 
      ecrypt = Encryption::Aes.new(:key => '123asdfwqer23414', :iv => 'asfd124315asfd')
      expect(ecrypt.key).not_to be(nil)
      expect(ecrypt.key.strip).not_to eq('')
      
      expect(ecrypt.key).not_to be(nil)
      expect(ecrypt.key.strip).not_to eq('')
    end
    
    it 'encrypts and decrypts using the IV and key successfully' do 
      ecrypt = Encryption::Aes.new
      data = File.open("spec/data/test_file.pdf", "rb") { |f| f.read }
      encrypted_data = ecrypt.encrypt(data)
      expect(encrypted_data).not_to eq(data)
      decrypted_data = ecrypt.decrypt(encrypted_data)
      expect(decrypted_data).to eq(data)
    end
  end

  describe Encryption::MD5Digest do 
    before(:each) do 
      aes = Encryption::Aes.new
      @data1 = aes.key

      aes = Encryption::Aes.new({ :key => aes.key, :iv => aes.iv })
      @data2 = aes.key

      aes = Encryption::Aes.new
      @data3 = aes.key
    end

    it 'creates a digest successfully' do 
      md5 = Encryption::MD5Digest.new
      expect(md5).not_to be(nil)
      digest = md5.digest(@data1)
     
      expect(digest).not_to be(nil)
      expect(digest).not_to eq('')
    end
    
    it 'creates the same digest for same data' do 
      md5 = Encryption::MD5Digest.new
      data1 = md5.digest(@data1)
      
      data2 = md5.digest(@data2)
      expect(data1).to eq(data2)
    end

    it 'creates different digest for different data' do 
      md5 = Encryption::MD5Digest.new
      data1 = md5.digest(@data1)

      data3 = md5.digest(@data3)
      expect(data1).not_to eq(data3)
    end
  end
end
