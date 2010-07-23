# todo:
# fetch from site (JSON GET)
# check that comment was added
class NewTask < Check

  WAIT_FOR = 60
  
  def subject
    "task #{param("key")}"
  end

  def run
    # todo: allow "run_in" to take a method name to be passed in to run!, so it can invoke it and then catch errors
    if param("key")
      check_inbox
    else
      send_email
    end
  end

  def send_email
    param("key", "#{Time.now.to_i}/#{rand(10000)}")
    OutgoingMessage.new(
            :to => "new@cohuman.com",
            :subject => subject,
            :body => subject
    ).deliver
    run_in(WAIT_FOR.seconds)
    PENDING
  end

  def check_inbox
    ok = false
    Receiver.new.scan do |message|
      if message.subject.include? param("key")
        ok = true
        message.delete
      end
    end
    if ok
      OK
    else
      self.reason = "did not receive confirmation email within #{WAIT_FOR} seconds"
      FAILED
    end
  end
end
