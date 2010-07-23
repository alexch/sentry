here = File.dirname(__FILE__);
require File.expand_path("#{here}/spec_helper")

describe Receiver do

  describe "initialization options" do
    it "defaults" do
      r = Receiver.new
      r.debug.should be_false
    end
  end

  describe '#scan' do
    # todo: test (with mock IMAP)
  end

  describe '#receive' do
    it "calls the processor block with each received email" do
      received_subjects = []
      r = Receiver.new do |message|
        received_subjects << message.subject
      end

      r.receive <<-EMAIL
From: sender@example.com
To: sentry@example.com
Subject: first
EMAIL

      r.receive <<-EMAIL
From: sender@example.com
To: sentry@example.com
Subject: second
EMAIL

      received_subjects.should == ["first", "second"]

    end
  end

end
