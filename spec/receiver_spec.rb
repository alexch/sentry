here = File.dirname(__FILE__);
require File.expand_path("#{here}/spec_helper")

describe Receiver do

  describe "initialization options" do
    it "defaults" do
      r = Receiver.new
      r.debug.should be_false
      r.keep.should be_false
    end

  end

  describe '#scan' do
    # todo: test (with mock IMAP)
  end

end
