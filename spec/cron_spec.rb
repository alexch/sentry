here = File.expand_path(File.dirname(__FILE__))
require "#{here}/spec_helper"

describe Cron do
  include DelayedJobSpecHelper
  attr_reader :cron

  before do
    @now = Time.now
    Time.stub!(:now).and_return(@now)

    Checker.all.destroy
    Delayed::Job.all.destroy

    @never_run = Checker.create(:check_type => "Win")
    pretend_run_at(@run_recently = Checker.create(:check_type => "Win"), 10.seconds.ago)
    pretend_run_at(@run_a_while_ago = Checker.create(:check_type => "Win"), 2.minutes.ago)

    @cron = Cron.summon
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
      cron.perform

      Delayed::Job.all.each do |job|
        unless job.payload_object.resource == cron
          job.payload_object.perform
          job.destroy
        end
      end

      [@never_run, @run_a_while_ago].each do |checker|
        checker.reload
        checker.last_run_at.should_not be_nil
        checker.last_run_at.should be_close(@now.to_datetime, 0.001)
      end
    end
  end

  def should_run_cron_in_a_minute(job)
    job.should_not be_nil
    job.run_at.should be_close(Time.now + 1.minute, 0.001)
    runner = job.payload_object
    runner.resource.should == cron
    runner.method_name.should == :perform
  end

  describe '#start' do
    it "is idempotent" do
      pending
    end

    it "schedules" do
      cron.job.should be_nil
      job = cron.start
      cron.job.should == job
      cron.reload.job.should == job
      should_run_cron_in_a_minute(job)
    end

    it "performs (scheduling all runnable checks)" do
      cron.start
      Delayed::Job.all.count.should == 3 # runnable_jobs + cron repeater
    end
  end

  it '#schedule' do
    cron.schedule
    Delayed::Job.all.count.should == 1
    job = cron.reload.job
    should_run_cron_in_a_minute(job)
  end

  describe '#stop' do
    it "is idempotent" do
      pending
    end

    it "removes the job" do
      cron.start
      cron.stop
      cron.reload.job.should be_nil
      Delayed::Job.all.each do |job|
        job.payload_object.resource.should_not == cron
      end
    end
  end
end
