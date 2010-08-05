here = File.expand_path(File.dirname(__FILE__))
require "#{here}/../spec_helper"

describe Fetch do
  before do
    @check = Fetch.new
  end

  it "is created in pending outcome" do
    @check.outcome.should == Check::PENDING
  end

  describe "params" do
    it "has defaults" do
      @check.param(:url).should == "http://example.com/"
    end

    it "can override defaults" do
      @check = Fetch.new(:params => {:url => "http://google.com/"})
      @check.param(:url).should == "http://google.com/"
    end

  end

  describe '#run' do
    it "tries to connect to host" do
      @check.param(:url, "http://localhost:9876/")
      lambda do
        @check.run
      end.should raise_error(Errno::ECONNREFUSED)
      # in the app, run! will call run and catch the exception
    end
  end

  describe "url parsing" do
    [
      ["http://example.com", "example.com", 80, "/"],
      ["http://example.com/", "example.com", 80, "/"],
      ["http://example.com:88/", "example.com", 88, "/"],
      ["http://example.com/foo/bar", "example.com", 80, "/foo/bar"],
    ].each do |a|
      url, host, port, path = a
      it "parses #{url}" do
        check = Fetch.new(:params => {:url => url})
        check.host.should == host
        check.port.should == port
        check.path.should == path
      end
    end

  end

end
