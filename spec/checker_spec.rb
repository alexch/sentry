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

  it "has a default schedule" do
    checker = Checker.new
    checker.schedule.should == 1
  end

  it "has a schedule" do
    checker = Checker.new(:schedule => "1")
    checker.schedule.should == 1
  end

  it "can't have 0 as a schedule" do
    checker = Checker.new(:schedule => "0")
    checker.should_not be_valid
  end

  it "can't have '' as a schedule" do
    checker = Checker.new(:schedule => "")
    checker.should_not be_valid
  end

  describe "spawning checks" do
    it "can't spawn a check until it's saved" do
      checker = Checker.new(:check_type => "Win")
      lambda { checker.perform }.should raise_error(Checker::UnsavedChecker)
      checker.save
      lambda { checker.perform }.should_not raise_error(Checker::UnsavedChecker)
    end

    it "can spawn a check with no params" do
      checker = Checker.create(:check_type => "Win")
      checker.params.should == {}
      check = checker.perform
      check.should be_a(Win)
      check.params.should == {}
    end

    it "knows the last time a check was spawned" do
      checker = Checker.create(:check_type => "Win")
      checker.last_run_at.should be_nil
      check = checker.perform
      checker.last_run_at.should be_close(check.created_at, 0.001)
    end

    it "knows the next time its check should spawn" do
      checker = Checker.create(:check_type => "Win")
      checker.perform
      checker.next_run_at.should be_close((Time.now + 1.minute).to_datetime, 0.001)
    end

    it "can spawn a check with params" do
      params = {"message" => "hi"}
      checker = Checker.create(:check_type => "Echo", :params => params)
      checker.params
      checker.params.should == params
      out = capturing_output do
        check = checker.perform
        check.params.should == params
      end
      out.should == "hi\n"      
    end

    it "associates with its spawned checks" do
      checker = Checker.create(:check_type => "Win")
      check = checker.perform
      checker.checks.should == [check]
      check.checker.should == checker
    end


  end

end
