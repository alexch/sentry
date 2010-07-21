here = File.expand_path(File.dirname(__FILE__))
require "#{here}/spec_helper"

describe Fetch do
  before do
    @check = Fetch.new
  end

  it "is created in pending outcome" do
    @check.outcome.should == :pending
  end

  describe "params" do
    it "has defaults" do
      @check[:url].should == "http://example.com/"
    end

    it "can override defaults" do
      @check = Fetch.new(:url => "http://google.com/")
      @check[:url].should == "http://google.com/"
    end

  end

  describe '#run' do
    it "tries to connect to host" do
      @check[:url] = "http://localhost:9876/"
      lambda do
        @check.run
      end.should raise_error(Errno::ECONNREFUSED)
      # in the app, run! will call run and catch the exception
    end
  end

end
