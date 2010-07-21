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

  class Draw < Check
    def run
      Check::PENDING
    end
  end

  class Fail < Check
    def run
      fail! "epic fail"
    end
  end

  attr_reader :check
  
  before do
    @check = Check.new
  end

  it "is created in pending outcome" do
    check.outcome.should == Check::PENDING
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

    it "succeeds if nothing is returned from run" do
      check = Win.new
      check.run!
      check.outcome.should == Check::OK
    end

    it "uses the outcome returned from run" do
      check = Draw.new
      check.run!
      check.outcome.should == Check::PENDING
    end

    it "catches exceptions" do
      check = Lose.new
      check.run!
      check.outcome.should == Check::FAILED
      check.reason.should == "FTL"
    end

    it "reports an exception" do
      Exceptional::Catcher.should_receive(:handle)
      Fail.new.run!
    end

    it "lets run call fail! on its own" do
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

  describe "#fail!" do
    it "has a reason" do
      lambda { check.fail! "why" }.should raise_error(CheckFailed)
      check.to_s.should include("why")
    end

    it "has a reason that's an exception" do
      lambda { check.fail! RuntimeError.new("why") }.should raise_error(CheckFailed)
      check.to_s.should include("why")
    end
  end

  describe "params" do
    it "has none by default" do
      check.params.should == {}
    end

    it "can get some" do
      check.param("foo", "bar")
      check.params.should == {"foo" => "bar"}
      check.param("foo").should == "bar"
    end

    it "interchanges string and hash keys on set" do
      check.param(:foo, "bar")
      check.params.should == {"foo" => "bar"}
      check.param("foo").should == "bar"
    end

    it "interchanges string and hash keys on get" do
      check.param(:foo, "bar")
      check.param(:foo).should == "bar"
    end

    it "does allows setting the live params hash" do
      check.params["foo"] = "bar"
      check.param("foo").should == "bar"
    end

    it "can be set in the constructor" do
      @check = Check.new(:params => {:foo => "bar"})
      check.params.should == {"foo" => "bar"}
      check.param(:foo).should == "bar"
    end

    it "sets dirtiness" do
      @check = Check.new(:params => {:foo => "bar"})
      @check.save
      @check.param(:foo, "baz")
      @check.should be_dirty
    end
  end

  describe "#to_s" do

    class Sample < Check
    end

    it "contains the class name" do
      Sample.new.to_s.should include("Sample")
    end

    it "contains the params" do
      Sample.new(:params => {:foo => "bar"}).to_s.should include({"foo" => "bar"}.inspect)
    end
  end

  describe "subclasses" do
    class Overrider < Check
      def default_params
        super.merge({"foo" => "bar"})
      end
    end
    it "can provide default params" do
      Overrider.new.param("foo").should == "bar"
    end
  end
end
