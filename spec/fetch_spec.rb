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
      @check[:timeout].should == 10
    end

    it "can override defaults" do
      @check = Fetch.new(:timeout => 9)
      @check[:timeout].should == 9
    end

    it "has a default host" do
      @check[:host].should == "example.com"
    end

    it "has a default path" do
      @check[:path].should == "/"
    end
  end

  describe '#run' do
    it "calls #failure! on failure" do
      @check[:host] = "localhost:9876"
      @check.run
      @check.outcome.should == :failure
      @check.to_s.should include("couldn't connect to host")
    end
  end

end
