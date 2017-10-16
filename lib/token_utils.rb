require 'twilio-ruby'

module TokenUtils
  def generate_and_send_token(options)
    confirmation_token_field = options[:confirmation_token_field]
    confirmation_sent_at_field = options[:confirmation_sent_at_field]
    message = options[:message]
    begin
      update_column confirmation_token_field, get_random_digits
    rescue ActiveRecord::RecordNotUnique => e
      @token_attempts = @token_attempts.to_i + 1
      retry if @token_attempts < MAX_TOKEN_RETRIES
      raise e, "Retries exhausted"
    end

    update_column confirmation_sent_at_field, Time.now
    send_token(options)
  end

  def send_token(options)
    confirmation_token_field = options[:confirmation_token_field]
    message = options[:message]
    #Send twilio SMS with confirmation token
    return true if ENV['WORK_OFFLINE']
    TwilioClient.get_instance.account.messages.create({
                                                        :from => TwilioClient.phone_number,
                                                        :to => options[:phone],
                                                        :body => message % self.read_attribute(confirmation_token_field)
                                                      })
    return true
  end

  def generate_token_for_field(field_name)
    update_column(field_name, get_random_digits)
  end

  def generate_unique_token_for_field(field_name)
    begin
      update_column field_name, SecureRandom.hex(3)
    rescue ActiveRecord::RecordNotUnique => e
      @token_attempts = @token_attempts.to_i + 1
      retry if @token_attempts < MAX_TOKEN_RETRIES
      raise e, "Retries exhausted"
    end
  end

  def get_random_digits
    (SecureRandom.random_number * 1000000).to_i
  end

  def get_random_alphanumeric(n = 6)
    range = [*'0'..'9',*'a'..'z']
    Array.new(6){ range.sample }.join
  end
end
