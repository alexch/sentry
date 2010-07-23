here = File.dirname(__FILE__);
require File.expand_path("#{here}/spec_helper")

describe ReceivedMessage do

  before do
    @subject = "buy groceries"
    @body = "milk\neggs\ngrapefruit"
    @incoming_message_id = "12345@example.com"
    @outgoing_message_id = "67890@sendgrid.net"
  end

  def build_mail(options = {})
    options = {:from => "alice@example.com",
               :to => "new@example.com",
               :subject => "Re: #{@subject}",
               :body => @body,
               :message_id => @incoming_message_id}.merge(options)

    attachments = [options[:attachment]].flatten.compact

    mail = Mail.new
    mail.to = options[:to]
    mail.from = options[:from]
    mail.subject = options[:subject]
    mail.message_id = "<#{options[:message_id]}>"
    mail.cc = options[:cc] if options[:cc]
    mail["Delivered-To"] = options[:delivered_to] if options[:delivered_to]
    mail.in_reply_to = "<#{options[:in_reply_to]}>" if options[:in_reply_to]

    if options[:references]
      mail.references = if options[:references].is_a? Array
        options[:references].join(", ")
      else
        options[:references]
      end
    end

    if options[:text_part] || options[:html_part]
      mail.part :content_type => "multipart/alternative", :content_disposition => "inline" do |p|
        p.part :content_type => "text/plain", :body => options[:text_part] if options[:text_part]
        p.part :content_type => "text/html", :body => options[:html_part] if options[:html_part]
      end
    else
      mail.body = options[:body]
    end

    attachments.each_with_index do |content, i|
      mail.add_file(:filename => "attachment#{i}.jpg", :content => content.to_s)
    end

    mail
  end

  def message_string(options = {})
    build_mail(options).to_s
  end

  def message(options = {})
    ReceivedMessage.new(message_string(options))
  end

  describe "#recipients" do
    it "collects to, cc, and Delivered-To" do
      received_message = ReceivedMessage.new(
              message_string(:to => ["alice@example.com", "bob@example.com"],
                             :cc => "charlie@example.com",
                             :delivered_to => "david@example.com"
              ))
      received_message.recipients.should =~ [
              "alice@example.com", "bob@example.com", "charlie@example.com", "david@example.com"
      ]
    end
  end

  it "strips 're:'s and 'fwd:'s from the subject" do
    msg = message(:subject => "Re: your brains")
    msg.subject.should == "your brains"

    msg = message(:subject => "re: your brains")
    msg.subject.should == "your brains"

    msg = message(:subject => "Re: fwd:re: your brains")
    msg.subject.should == "your brains"

    msg = message(:subject => "re: fwd: RE:re:fwd: your brains")
    msg.subject.should == "your brains"
  end

  describe "if from is nil" do
    it "reports an exception for it" do
      s = capturing_output do
        lambda do
          ReceivedMessage.new("WTF")
        end.should raise_error("invalid email: from was empty")
      end
      s.should =~ /bad email received/
    end
  end

  describe "#body" do
    it "turns \\r\\n into \\n" do
      message(:body => "my\r\ndog\r\n\r\nhas fleas").
              body.should == "my\ndog\n\nhas fleas"
    end

    it "prefers a text mime part to an html mime part" do
      message(:body => nil, :text_part => "hello!", :html_part => "hel<b>lo</b>!").body.should == "hello!"
    end
  end

  def send_outgoing_message
    headers = {:to => @alice.primary_email_address, :from => EmailConfig.get.from,
               :subject => "notification", :body => "something happened to #{@run.name}"}
    outgoing = OutgoingMessage.new(headers << {:task => @run})
    @mail = Mail.new(headers)
    outgoing.stub!(:send_email).and_return(@mail)
    outgoing.deliver
    outgoing.reload.message_id.should == @mail.message_id
    outgoing
  end

  describe '#process_message_ids' do
    it 'removes angle brackets and duplicates, ignores blanks, and works with arrays' do
      message.send(:process_message_ids,
                   "<foo>, <bar>, foo", "", "<bar>, baz", ["foo"]).
              should == ["foo", "bar", "baz"]
    end
  end

  it 'can be marked for deletion' do
    m = message
    m.delete?.should be_false
    m.delete
    m.delete?.should be_true
  end

end
