require 'resque/server'

class SecureResqueServer < Resque::Server

  use Rack::Auth::Basic, "Restricted Area" do |username, password|
    [username, password] == [ENV['RESQUE_WEB_HTTP_BASIC_AUTH_USER'], ENV['RESQUE_WEB_HTTP_BASIC_AUTH_PASSWORD']]
  end

end