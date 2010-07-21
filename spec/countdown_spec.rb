here = File.expand_path(File.dirname(__FILE__))
require "#{here}/spec_helper"

describe Countdown do
  it "succeeds with 0 sec remaining" do
    check = Countdown.new(:params => {:sec => "0"})
    check.run!
    check.outcome.should == Check::OK
  end

  it "queues up a delayed job" do
    check = Countdown.new(:params => {:sec => "10"})
    check.run!
    check.reload
    check.outcome.should == Check::PENDING
    check.param("sec").should == 9
    job = Delayed::Job.last
    job.handler.should include("Countdown")
    job.run_at.should be_close(Time.now + 1, 0.01)
  end
end
