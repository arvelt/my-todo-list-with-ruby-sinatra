require 'rspec'
require 'rack/test'
RSpec.configure do |conf|
  ENV['RACK_ENV'] = 'test'
  conf.include Rack::Test::Methods
  
  def app
    Main.new
  end
  
  def session
    last_request.env['rack.session']
  end
end
