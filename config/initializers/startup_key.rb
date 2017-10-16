module Rails
  #Should be retrieved from S3 - a private bucket only accessible by selective
  #team in the Company
  def self.startup_password
    startup_pass1 = ENV['STARTUP_PASS1']
    startup_pass2 = ENV['STARTUP_PASS2']
    fail "Please provide STARTUP_PASS1 and STARTUP_PASS2 environment variables with the 2 passwords used to construct the root encryption password of Docyt" if (startup_pass1.nil? or startup_pass2.nil?)

    # This is a startup password which is constructed using 2 passwords which will be known to 2 different "administrators" of Docyt. Both administrators will have to provide their password for the application server to start successfully. @startup_pass is then used as the "Docyt password" for all the encryptions that Docyt application has to do on behalf of Docyt.
    @startup_password ||= startup_pass1 + startup_pass2
  end
  
  #Should be retrieved from S3 - a private bucket only accessible by selective 
  #team in the Company 
  def self.private_key
    ENV['STARTUP_PRIVATE_KEY']
  end
  
  def self.public_key
    ENV['STARTUP_PUBLIC_KEY']
  end

  def self.symmetric_key
    ENV['AES_KEY']
  end

  def self.symmetric_iv
    ENV['AES_IV']
  end

  def self.startup_password_hash
    digest = OpenSSL::Digest::MD5.new.digest(self.startup_password)
    Base64.encode64(digest)
  end

  def self.set_mobile_app_version(version)
    @mobile_app_version = version
  end

  def self.mobile_app_version
    @mobile_app_version
  end

  #User's password hash is passed into certain requests because it is needed to 
  #decrypt user's private key. This getter/setter methods are used to set it
  #globally so they can accessed from anywhere in the app
  def self.set_user_password_hash(pass)
    @user_password_hash = pass
  end

  def self.set_user_oauth_token(token)
    @user_oauth_token = token
  end

  def self.set_app_type(app_type)
    @app_type = app_type
  end

  def self.user_password_hash
    @user_password_hash
  end

  def self.user_oauth_token
    @user_oauth_token
  end

  def self.app_type
    @app_type
  end
end
