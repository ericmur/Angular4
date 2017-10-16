require 'system_encryption'

namespace :encryption do
  desc 'Create System AES keys; both iv and key will be encrypted with system public keys and base64 encoded'
  task :create_system_aes_keys => :environment do |t, args|
    encryption = Encryption::Aes.new
    sys_pgp = SystemEncryption.new(:encryption_type => 'pgp')
    encrypted_key = sys_pgp.encrypt(encryption.key, :encode_base64 => true)
    encrypted_iv = sys_pgp.encrypt(encryption.iv, :encode_base64 => true)

    puts "Key: "
    puts "#{encrypted_key}"
    puts
    puts
    puts "IV: "
    puts "#{encrypted_iv}"
  end
end
