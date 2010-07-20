here = File.expand_path(File.dirname(__FILE__))
require "#{here}/spec_helper"

describe Check do
  attr_reader :check
  
  before do
    @check = Check.new
  end

  it "is created in pending outcome" do
    check.outcome.should == :pending
  end

  it "succeeds" do
    check.success!
    check.outcome.should == :success
  end

  describe '#run' do
    it "raises an exception if left undefined" do
      lambda {Check.new.run}.should raise_error(NotImplementedError)
    end
  end

  describe "#failure!" do
    it "sets the outcome" do
      check.failure!
      check.outcome.should == :failure
    end

    it "reports an exception" do
      Exceptional::Catcher.should_receive(:handle).with(CheckFailed.new(check.to_s))
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
