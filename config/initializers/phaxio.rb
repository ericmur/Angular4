require 'phaxio'

config_file = YAML.load(ERB.new(File.read("#{Rails.root}/config/phaxio.yml.erb")).result)[Rails.env]

Phaxio.config do |config|
  config.api_key = config_file['api_key']
  config.api_secret = config_file['api_secret']
end
