here = File.dirname(__FILE__);
require File.expand_path("#{here}/spec_helper")

describe EmailConfig do
  it "allows dot-call access to its data" do
    config = EmailConfig.new({:a => 3})
    config.a.should == 3
  end
  it "allows [] access to its data" do
    config = EmailConfig.new({:a => 3})
    config[:a].should == 3
  end
  it "converts nested hashes into EmailConfig objects" do
    config = EmailConfig.new({:a => {:b => 3}})
    config.a.should be_a EmailConfig
    config.a.b.should == 3
  end
end
