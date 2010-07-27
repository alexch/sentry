# todo:
# fetch from site (JSON GET)
# check that comment was added
class NewTask < Check

  def default_params
    super.merge("wait_for" => 60)
  end

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

  def wait_for
    param("wait_for").to_i.seconds
  end

  def send_email
    param("key", "#{Time.now.to_i}/#{rand(10000)}")
    OutgoingMessage.new(
            :to => "new@cohuman.com",
            :subject => subject,
            :body => subject
    ).deliver
    run_again(wait_for.seconds)
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
      self.reason = "did not receive confirmation email within #{wait_for} seconds"
      FAILED
    end
  end
end
