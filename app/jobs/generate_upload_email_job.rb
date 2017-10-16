class GenerateUploadEmailJob < ActiveJob::Base
  queue_as :default

  def perform(uid)
    u=User.find(uid)
    words = File.readlines("/usr/share/dict/words")
    email = get_rand_email(words)
    while User.find_by_upload_email(email)
      email = get_rand_email(words)
    end
    u.upload_email = email
    u.save!
  end

  def get_rand_email(words)
    words_size_6 = words.map {|a| a.gsub(/[^0-9a-z]/i,'').downcase }.select { |a| a.size < 7 }
    rng = Random.new
    word1 = words_size_6[rng.rand(words_size_6.size)].gsub("\n",'').downcase
    word2 = words_size_6[rng.rand(words_size_6.size)].gsub("\n",'').downcase
    "#{Rails.settings['upload_email_prefix']}+" + word1 + "." + word2 + "@docyt.io"
  end
end
