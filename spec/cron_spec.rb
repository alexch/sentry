here = File.expand_path(File.dirname(__FILE__))
require "#{here}/spec_helper"

describe Cron do
  include DelayedJobSpecHelper

  before do
    @now = Time.now
    Time.stub!(:now).and_return(@now)

    Checker.all.destroy

    @never_run = Checker.create(:check_type => "Win")
    pretend_run_at(@run_recently = Checker.create(:check_type => "Win"), 10.seconds.ago)
    pretend_run_at(@run_a_while_ago = Checker.create(:check_type => "Win"), 2.minutes.ago)
  end

  def pretend_run_at(checker, time)
    check = checker.perform
    check.update(:created_at => time)
  end

  it "can be summoned from the void" do
    Cron.all.destroy
    Cron.count.should == 0
    Cron.summon
    Cron.count.should == 1
    Cron.summon
    Cron.count.should == 1
  end

  describe '#runnable_checkers' do
    it "lists all checkers that need running" do
      Cron.summon.runnable_checkers.should =~ [@never_run, @run_a_while_ago]
    end
  end

  describe '#perform' do
    it "schedules runs for all relevant checks" do
      cron = Cron.summon
      Delayed::Job.all.destroy
      job = cron.perform
      Delayed::Job.all.count.should == 2
      work_off # runs all jobs
      [@never_run, @run_a_while_ago].each do |checker|
        checker.reload
        checker.last_run_at.should_not be_nil
        checker.last_run_at.should be_close(@now.to_datetime, 0.001)
      end
    end
  end

  describe "tick tock" do
    attr_reader :cron
    before do
      Delayed::Job.all.destroy      
      @cron = Cron.summon
    end

    it "starts" do
      cron.job.should be_nil
      job = cron.start
      cron.job.should_not be_nil
      cron.job.should == job
      cron.reload.job.should == job
      job.payload_object.resource.should == cron
    end

    it "performs on start" do
      cron.start
      Delayed::Job.all.count.should == 3 # runnable_jobs + cron repeater
    end

    it "stops" do
      cron.start
      cron.stop
      Delayed::Job.all.each do |job|
        job.payload_object.resource.should_not == cron
      end
    end
  end

end
