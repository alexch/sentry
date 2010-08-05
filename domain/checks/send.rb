class Send < Check
  def self.description
    "Immediately send an email from Sentry"
  end

  def default_params
    super.merge(:to => "nobody@example.com")
  end

  def run
    to = param("to")
    message = OutgoingMessage.new(:to => to, :subject => "hello from Sentry", :body => "hello, it's #{Time.now}")
    message.deliver
    OK
  end
end
