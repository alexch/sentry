here = File.dirname(__FILE__); require File.expand_path("#{here}/spec_helper")

describe Hash do
  describe "#remap" do
    it "does nothing to an empty hash" do
      {}.remap { |key, value| [key, value] }.should == {}
    end

    it "remaps a hash with two items" do
      {:a => 1, :b => 2}.remap { |key, value| [value, key] }.should == {1 => :a, 2 => :b}
    end

    it "skips entries that map to nil" do
      {:a => 1, :b => 2}.remap do |key, value|
        if value == 1
          nil
        else
          [key, value]
        end
      end.should == {:b => 2}
    end

    it "works if one of the values is a hash" do
      {:a => 1, :b => {:x => 7}}.remap { |key, value| [key, value] }.should == {:a => 1, :b => {:x => 7}}
    end
  end

  describe '#to_params' do
    it "converts a hash" do
      s = {:a => 1, :b => 2}.to_params
      (s == "a=1&b=2" || s == "b=2&a=1").should be_true
    end

    it "cgi escapes its parameters" do
      s = {"foo" => "'Stop!' said Fred"}.to_params
      s.should == "foo=%27Stop%21%27+said+Fred"
    end
  end

  describe '#from_params' do
    it "converts a CGI string" do
      Hash.from_params("a=1&b=2").should == {"a" => "1", "b" => "2"}
    end

    it "cgi unescapes its parameters" do
      s = "foo=%27Stop%21%27+said+Fred"
      Hash.from_params(s).should == {"foo" => "'Stop!' said Fred"}
    end
  end

  describe 'shovel as merge' do
    it '<< is aliased to merge' do
      ({:a => 1} << {:b => 2}).should == ({:a => 1, :b => 2})
    end
  end

  describe '#stringify_keys!' do
    # this is also defined in active_support
    it "converts all keys to strings" do
      h = {:foo => "bar"}
      h.stringify_keys!
      h.should == {"foo" => "bar"}
    end
  end

  describe '#stringify_keys' do
    # this is also defined in active_support
    it "converts all keys to strings" do
      h = {:foo => "bar"}
      h.stringify_keys.should == {"foo" => "bar"}
      h.should == {:foo => "bar"}
    end
  end
end
