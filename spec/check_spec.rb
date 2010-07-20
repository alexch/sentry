here = File.expand_path(File.dirname(__FILE__))
require "#{here}/spec_helper"

describe Check do
  it "is created in pending state" do
    check = Check.new
    check.state.should == :pending
  end

  it "succeeds" do
    check = Check.new
    check.success!
    check.state.should == :success
  end

  describe '#run' do
    it "raises an exception if left undefined" do
      lambda {Check.new.run}.should raise_error(NotImplementedError)
    end
  end
end
