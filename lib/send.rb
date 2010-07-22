class Send < Check

  def run
    to = param("to")
    message = OutgoingMessage.new(:to => to, :subject => "hello from Sentry", :body => "hello, it's #{Time.now}")
    message.deliver
    OK
  end
end
