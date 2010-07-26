here = File.expand_path(File.dirname(__FILE__))
require "#{here}/spec_helper"

describe Params do
  class Dog
    include DataMapper::Resource
    include Params

    property :id, Serial

  end

  attr_reader :dog

  before do
    @dog = Dog.new
  end

  describe "params" do
    it "has none by default" do
      dog.params.should == {}
    end

    it "can get some" do
      dog.param("foo", "bar")
      dog.params.should == {"foo" => "bar"}
      dog.param("foo").should == "bar"
    end

    it "interchanges string and hash keys on set" do
      dog.param(:foo, "bar")
      dog.params.should == {"foo" => "bar"}
      dog.param("foo").should == "bar"
    end

    it "interchanges string and hash keys on get" do
      dog.param(:foo, "bar")
      dog.param(:foo).should == "bar"
    end

    it "does not allow setting the live params hash" do
      lambda do
        dog.params["foo"] = "bar"
      end.should raise_error("Sorry, but you can't modify the params object directly. Try obj.param(\"foo\", \"bar\") instead.")
    end

    it "can be set in the constructor" do
      @dog = Check.new(:params => {:foo => "bar"})
      dog.params.should == {"foo" => "bar"}
      dog.param(:foo).should == "bar"
    end

    it "sets dirtiness" do
      @dog = Check.new(:params => {:foo => "bar"})
      @dog.save
      @dog.param(:foo, "baz")
      @dog.should be_dirty
    end
  end

  describe "subclasses" do
    class Overrider < Check
      def default_params
        super.merge({"foo" => "bar"})
      end
    end
    it "can provide default params" do
      dog = Overrider.new
      dog.param("foo").should == "bar"
      dog.reload
      dog.param("foo").should == "bar"
    end
  end
end
