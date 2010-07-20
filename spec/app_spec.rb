here = File.expand_path(File.dirname(__FILE__))
require "#{here}/spec_helper"

require "rack/test"

describe "app" do
  include Rack::Test::Methods
  
  def response
    last_response
  end

  def app
    SentryApp
  end

  require 'app'

  it "says hi" do
    get "/"
    response.should be_ok
    response.body.should include("sentry")
  end
end
