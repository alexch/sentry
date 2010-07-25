here = File.expand_path(File.dirname(__FILE__))
require "#{here}/spec_helper"

describe Checker do

  attr_reader :checker

  it "needs to know its check's class" do
    checker = Checker.new
    checker.valid?.should be_false
    lambda { checker.save }.should raise_error(DataMapper::SaveFailureError)
    checker.check_type = "Check"
    checker.valid?.should be_true
  end

  describe "spawning checks" do

    it "can't spawn a check until it's saved" do
      checker = Checker.new(:check_type => "Win")
      lambda { checker.run_check }.should raise_error(Checker::UnsavedChecker)
      checker.save
      lambda { checker.run_check }.should_not raise_error(Checker::UnsavedChecker)
    end

    it "can spawn a check with no params" do
      checker = Checker.create(:check_type => "Win")
      checker.params.should == {}
      check = checker.run_check
      check.should be_a(Win)
      check.params.should == {}
    end

    it "can spawn a check with params" do
      params = {"message" => "hi"}
      checker = Checker.create(:check_type => "Echo", :params => params)
      checker.params
      checker.params.should == params
      check = checker.run_check
      check.params.should == params
    end

    it "associates with its spawned checks" do
      checker = Checker.create(:check_type => "Win")
      check = checker.run_check
      checker.checks.should == [check]
      check.checker.should == checker
    end
  end
end
