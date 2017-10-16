class TwilioClient
  def self.twilio_config
    return YAML.load_file('config/twilio.yml')[Rails.env]
  end
  
  def self.get_instance
    twilio_account_sid = self.twilio_config['account_sid'] || ENV['TWILIO_ACCOUNT_SID']
    twilio_auth_token = self.twilio_config['auth_token'] || ENV['TWILIO_AUTH_TOKEN']
    @twilio_client ||= Twilio::REST::Client.new twilio_account_sid, twilio_auth_token
  end

  def self.get_lookup_instance
    twilio_account_sid = self.twilio_config['account_sid'] || ENV['TWILIO_ACCOUNT_SID']
    twilio_auth_token = self.twilio_config['auth_token'] || ENV['TWILIO_AUTH_TOKEN']
    @lookup_client = Twilio::REST::LookupsClient.new twilio_account_sid, twilio_auth_token
  end

  def self.phone_number
    self.twilio_config['phone_number']
  end

  def self.valid_phone_number?(phone_number)
    begin
      response = self.get_lookup_instance.phone_numbers.get(phone_number)
      response.phone_number #if invalid, throws an exception. If valid, no problems.
      return true
    rescue => e
      if e.code == 20404
        return false
      else
        raise e
      end
    end
  end
end
