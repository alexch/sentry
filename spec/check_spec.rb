here = File.expand_path(File.dirname(__FILE__))
require "#{here}/spec_helper"

describe Check do
  attr_reader :check
  
  before do
    @check = Check.new
  end

  it "is created in pending outcome" do
    check = Check.new
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
  end
end
