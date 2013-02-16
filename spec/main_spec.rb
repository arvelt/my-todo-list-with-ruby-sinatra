require './main'
require 'rspec'
require 'rack/test'

set :environment, :devlopment

describe 'The HelloWorld App' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  it "says hello" do
    get '/'
    last_response.should be_ok
#    last_response.body.should eq 'Hello World'
  end

#  it "says hello to a person" do
#    get '/', :name => 'Simon'
#    last_response.body.should include('Simon')
#  end
end