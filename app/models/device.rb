require 'token_utils'

class Device < ActiveRecord::Base
  include TokenUtils
  
  MAX_TOKEN_RETRIES = 3
  NEW_DEVICE_MESSAGE = "Your code is: %s. Please confirm your new device that is being used to access your Docyt account using this code."
  belongs_to :user

  attr_accessor :input_pass_code
  
  validates :device_uuid, :presence => true, :uniqueness => { :scope => :user_id }

  before_save :encrypt_pass_code, :unless => Proc.new { |obj| obj.input_pass_code.nil? }
  after_save  :clear_pass_code
  after_create :send_confirmation_token, :unless => Proc.new { |d| d.confirmed_at }

  def confirm
    self.confirmed_at = Time.now
    self.confirmation_token = nil #Release the token so it can be reused
    if self.save
      send_new_device_added_email
      return true
    else
      return false
    end
  end

  def resend_new_device_code
    send_token(:confirmation_token_field => :confirmation_token, :phone => self.user.phone_normalized, :message => NEW_DEVICE_MESSAGE)
  end

  def decrypt_pass_code
    pgp = nil
    if Rails.app_type == User::DOCYT_BOT_APP
      pgp = Encryption::Pgp.new({ :password => Rails.user_oauth_token, :private_key => self.user.oauth_token_private_key })
    else
      raise "Invalid app type: #{Rails.app_type}"
    end
    pgp.decrypt(self.pass_code)
  end
  
  private
  def send_confirmation_token
    generate_and_send_token(:confirmation_token_field => :confirmation_token, :confirmation_sent_at_field => :confirmation_sent_at, :phone => self.user.phone_normalized, :message => NEW_DEVICE_MESSAGE)
  end

  def encrypt_pass_code
    pgp = Encryption::Pgp.new({ :public_key => self.user.public_key })
    self.pass_code = pgp.encrypt(self.input_pass_code)
  end

  def clear_pass_code
    self.input_pass_code = nil
  end

  def send_new_device_added_email
    if self.user.email_confirmed? && self.confirmed_at.present?
      UserMailer.new_device_added(self.user, self).deliver_later
    end
  end
end
