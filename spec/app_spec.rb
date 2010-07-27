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

  describe "POST /check" do
    before do
      Check.all.destroy
    end

    it "creates a check" do
      post "/check", "check_type" => "Win",
                     "params[foo]" => "bar"
      check = Check.last
      check.should be_a(Win)
      check.param("foo").should == "bar"
    end

    it "creates a check with params named after the type" do
      post "/check", "check_type" => "Win",
                     "Win[foo]" => "bar",
                     "Lose[foo]" => "boo"
      check = Check.last
      check.should be_a(Win)
      check.param("foo").should == "bar"
    end

    it "creates a check if a schedule is blank" do
      post "/check", "check_type" => "Win",
                     "params[foo]" => "bar",
                     "schedule" => ""
      check = Check.last
      check.should be_a(Win)
      check.param("foo").should == "bar"
    end

    it "creates a checker if a schedule is provided" do
      post "/check", "check_type" => "Win",
                     "params[foo]" => "bar",
                     "schedule" => "1"

      check = Check.last
      check.should be_a(Win)
      check.param("foo").should == "bar"

      checker = Checker.last
      checker.check_type.should == "Win"
      checker.check_class.should == Win
      checker.schedule.should == 1
    end
  end
end
