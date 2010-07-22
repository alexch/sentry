here = File.dirname(__FILE__);
require File.expand_path("#{here}/spec_helper")

describe OutgoingMessage do

  class TestBodyWidget < Widget
    def content
      text "$7.99\nplus tax\n"
      a "internal", :href => "/foo"
      a "external", :href => "http://external.com/bar"
    end
  end

  default_options =
          {
                  :to => 'alex@stinky.com',
                  :subject => 'price of rice',
                  :body => TestBodyWidget.new
          }

  define_method(:email_options) do
    default_options.dup
  end

  def message(options = {})
    OutgoingMessage.new(email_options.merge(options))
  end

  before do
    OutgoingMessage.clear
  end

  describe 'body' do

    it 'works with a plain text body' do
      plain_text_body = 'Old-school no-frills plain text here.'
      m = message(:body => plain_text_body)
      m.body_to_text.should include plain_text_body
      m.body_to_html.should include plain_text_body
    end

    it 'works with an Erector widget body' do
      class Song < Erector::Widget
        def content
          p :class => 'song' do
            ul do
              li "My dog"
              li do
                text "has "
                i "fleas"
              end
            end
          end
          p :class => "long" do
            text "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut auctor auctor elementum. Sed et dolor metus, sit amet pharetra tellus. Integer eget massa magna, ut molestie risus. Aliquam erat volutpat. Nullam nibh arcu, blandit nec tempus quis, scelerisque vel velit. Curabitur fringilla eleifend metus, quis adipiscing lectus convallis non. Cras auctor venenatis quam. Vivamus sit amet dolor purus, tristique vehicula est. Vivamus convallis enim et nunc molestie tincidunt vel id magna. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Aenean ac vehicula metus. Mauris lorem massa, accumsan vitae blandit ac, mollis sed risus. Maecenas viverra elit nec tellus ornare dignissim. Nunc congue mattis leo non consectetur. Etiam ligula lacus, suscipit id pulvinar cursus, tempus vitae dui. Integer pellentesque venenatis sem, sed egestas dolor tristique ac. Sed elementum fermentum convallis. Ut auctor varius est, in varius nunc sodales id. Aenean nisi metus, congue eu faucibus vel, scelerisque ut orci."
          end
        end
      end
      widget_body = Song.new
      m = message(:body => widget_body)
      m.body_to_html.should include widget_body.to_pretty(:max_length => 72)
    end
  end

  describe 'fields' do
    attr_reader :m

    before do
      @m = message
    end

    it "has from, to, subject, and body" do
      m.mail.from.should == [EmailConfig.get.from]
      m.mail.to.should == ['alex@stinky.com']
      m.body_to_text.should include "$7.99\nplus tax"
    end

    default_options.keys.each do |key|
      next if key == :from
      it "requires a '#{key}' field" do
        lambda do
          options = email_options.dup
          options.delete(key)
          @m = OutgoingMessage.new(options)
        end.should raise_error "missing required field '#{key}'"
      end
    end

    it 'accepts a Sendgrid Category' do
      @m = message(:category => "foo")
      @m.category.should == "foo"
      @m.assemble_mail['X-SMTPAPI'].to_s.should == '{"category": "foo"}'
    end

    it 'accepts a Sender' do
      joe = 'joe@example.com'
      m = message(:sender => joe)
      m.sender.should == joe
      m.mail['sender'].to_s.should == joe
    end

    it "accepts multiple from addresses" do
      addresses = ["alice@example.com (Alice Jones)", "bob@example.com (Bob Smith)"]
      m = message(:from => addresses)
      m.from.should == addresses
      m.mail.to_s.should =~ /^From: #{Regexp.escape addresses[0]},\s*#{Regexp.escape addresses[1]}/m
    end

    it 'accepts a Reply-To' do
      joe = 'joe@example.com'
      m = message(:reply_to => joe)
      m.reply_to.should == joe
      m.mail['reply_to'].to_s.should == joe
      m.mail.to_s.split("\n").grep(/^Reply-To:/).first.strip.should == "Reply-To: #{joe}"
    end
  end

  it "tracks sent messages" do
    OutgoingMessage.sent.should == []
    m = message
    m.deliver
    OutgoingMessage.sent.should == [m]
  end

  it "works with multiple 'to' addresses" do
    m = message(:to => ['alex@stinky.com', 'ernie@example.com'])
    m.to.should == ['alex@stinky.com', 'ernie@example.com']
    m.assemble_mail.to_s.should match(/To: alex@stinky.com,\s*ernie@example.com\b/m)
  end

  it "doesn't send messages if to is empty" do
    m = message(:to => [])
    m.deliver
    OutgoingMessage.sent.should == []
  end

  it "doesn't send messages if to has nils" do
    m = message(:to => [nil, nil])
    m.deliver
    OutgoingMessage.sent.should == []
  end

  describe "correct html" do
    it "has <br> tags in the html version of a text message" do
      m = message(:body => "sex\ndrugs\nrock and roll")
      m.body_to_html.should include("sex<br>drugs<br>rock and roll")
    end

    it "rewrites anchors that start with / to point back to the site" do
      m = message
      m.body_to_html.should include("href=\"#{OutgoingMessage.url('foo')}\">internal</a>")
      m.body_to_html.should include("href=\"http://external.com/bar\">external</a>")
    end
  end

  describe '#url' do
    it 'makes a nice full URL' do
      OutgoingMessage.url.should == "http://example.com/"
    end

    it 'makes a path into a full URL' do
      OutgoingMessage.url("foo").should == "http://example.com/foo"
      OutgoingMessage.url("/foo").should == "http://example.com/foo"
    end

    it 'is configurable' do
      begin
        OutgoingMessage.host = "foo.org"
        OutgoingMessage.url.should == "http://foo.org/"
        OutgoingMessage.url("bar").should == "http://foo.org/bar"
      ensure
        OutgoingMessage.host = "example.com"
      end
    end

    it 'supports params' do
      OutgoingMessage.url("foo/bar", :selected => 'settings').should == "http://example.com/foo/bar?selected=settings"
    end
  end

  describe "SMTP errors" do
    before do
      OutgoingMessage.fake(false)
      @m = message

      def @m.send_email(config)
        mail.ready_to_send!
        @number_of_raises ||= 0
        @number_of_raises += 1
        if @number_of_raises <= (@fail_this_many_times_before_succeeding || 2)
          error_class = @error_class || RuntimeError
          raise error_class.new "fake SMTP failure ##{@number_of_raises}"
        else
          @sent = true
        end
        mail
      end
    end

    after do
      OutgoingMessage.fake(true)
    end

    it "fails once then succeeds" do
      @m.instance_variable_set(:@fail_this_many_times_before_succeeding, 1)
      Exceptional::Catcher.should_not_receive(:handle) # .with(RuntimeError.new("fake SMTP failure #3"))
      lambda { @m.deliver }.should_not raise_error
      @m.instance_variable_get(:@sent).should == true
    end

    it "tries twice then succeeds" do
      @m.instance_variable_set(:@fail_this_many_times_before_succeeding, 2)
      Exceptional::Catcher.should_not_receive(:handle) # .with(RuntimeError.new("fake SMTP failure #3"))
      lambda { @m.deliver }.should_not raise_error
      @m.instance_variable_get(:@sent).should == true
    end

    it "tries twice then fails" do
      @m.instance_variable_set(:@fail_this_many_times_before_succeeding, 3)
      Exceptional::Catcher.should_receive(:handle) # .with(RuntimeError.new("fake SMTP failure #3"))
      capturing_output do
        lambda do
          @m.deliver
        end.should raise_error(RuntimeError, "fake SMTP failure #3")
      end
      @m.instance_variable_get(:@sent).should be_nil
    end

    # see http://lindsaar.net/2007/12/9/rbuf_filltimeout-error
    it "doesn't abort when receiving a Timeout::Error" do
      @m.instance_variable_set(:@fail_this_many_times_before_succeeding, 1)
      @m.instance_variable_set(:@error_class, Timeout::Error)
      lambda { @m.deliver }.should_not raise_error
      @m.instance_variable_get(:@sent).should == true
    end
  end

end
