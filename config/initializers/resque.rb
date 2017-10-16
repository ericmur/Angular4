rails_root = File.dirname(__FILE__) + '/../..'
rails_env  = ENV['RAILS_ENV'] || 'development'

if defined?(Rails)
  rails_env = Rails.env
  rails_root = Rails.root
end

redis_config = YAML.load_file("#{rails_root}/config/resque.yml")
Resque.redis = redis_config[rails_env]
