here = File.expand_path(File.dirname(__FILE__))
require "#{here}/spec_helper"

describe Check do
  class Win < Check
    def run
      # no news is good news
    end
  end

  class Lose < Check
    def run
      raise "FTL"
    end
  end

  class Fail < Check
    def run
      failure! "epic fail"
    end
  end

  attr_reader :check
  
  before do
    @check = Check.new
  end

  it "is created in pending outcome" do
    check.outcome.should == Check::PENDING
  end

  describe '#ok!' do
    it "succeeds" do
      check.ok!
      check.outcome.should == Check::OK
    end
  end

  describe '#run' do
    it "raises an exception if left undefined" do
      lambda {Check.new.run}.should raise_error(NotImplementedError)
    end
  end

  describe '#run!' do
    it "calls run" do
      check.should_receive(:run)
      check.run!
    end

    it "allows ok" do
      check = Win.new
      check.run!
      check.outcome.should == Check::OK
    end

    it "catches exceptions" do
      check = Lose.new
      check.run!
      check.outcome.should == Check::FAILED
      check.reason.should == "FTL"
    end

    it "lets run call failure" do
      check = Fail.new
      check.run!
      check.outcome.should == Check::FAILED
      check.reason.should == "epic fail"
    end

    it "saves the check" do
      check = Win.new
      check.run!
      check.should be_saved
      check.id.should_not be_nil
    end
  end

  describe "#failure!" do
    it "sets the outcome" do
      check.failure!
      check.outcome.should == Check::FAILED
    end

    it "reports an exception" do
      mock = Exceptional::Catcher.should_receive(:handle)
      mock.with(CheckFailed.new(check.to_s)) if RUBY_VERSION > "1.9"
      check.failure!
    end

    it "has a reason" do
      check.failure! "why"
      check.to_s.should include("why")
    end

    it "has a reason that's an exception" do
      check.failure! RuntimeError.new("why")
      check.to_s.should include("why")
    end
  end

  describe "params" do
    it "has none by default" do
      check.params.should == {}
    end

    it "can get some" do
      check["foo"] = "bar"
      check.params.should == {"foo" => "bar"}
      check["foo"].should == "bar"
    end

    it "interchanges string and hash keys on set" do
      check[:foo] = "bar"
      check.params.should == {"foo" => "bar"}
      check["foo"].should == "bar"
    end

    it "interchanges string and hash keys on get" do
      check[:foo] = "bar"
      check[:foo].should == "bar"
    end

    it "does not allow setting the live params hash" do
      lambda do
        check.params["foo"] = "bar"
      end.should raise_error
    end

    it "can be set in the constructor" do
      @check = Check.new(:foo => "bar")
      check.params.should == {"foo" => "bar"}
      check[:foo].should == "bar"
    end
  end

  describe "#to_s" do

    class Sample < Check
    end

    it "contains the class name" do
      Sample.new.to_s.should include("Sample")
    end

    it "contains the params" do
      Sample.new(:foo => "bar").to_s.should include({"foo" => "bar"}.inspect)
    end
  end
end
