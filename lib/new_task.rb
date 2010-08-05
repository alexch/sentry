# todo:
# fetch content from site (JSON GET) in parallel; fail if either email or content is missing
# check that comment was added
# unit test
class NewTask < Check

  def self.description
    "Send email to new@cohuman.com, which should create a new task. Wait for the confirmation email."
  end

  def default_params
    super.merge("period" => 30, "limit" => 600, "to" => "new@cohuman.com")
  end

  def subject
    "task #{param("key")}"
  end

  def run
    # todo: allow "run_again" to take a method name to be passed in to run!, so we don't need this switch
    if param("key")
      check_inbox
    else
      send_email
    end
  end

  def period
    param("period").to_i
  end

  def send_email
    param("key", "#{Time.now.to_i}/#{rand(10000)}")
    OutgoingMessage.new(
            :to => param("to"),
            :subject => subject,
            :body => subject
    ).deliver
    run_again(period.seconds)
    PENDING
  end

  def duration
    (Time.now - created_at).to_i
  end

  def limit
    param("limit").to_i
  end

  def check_inbox
    ok = false
    Receiver.new.scan do |message|
      if message.subject.include? param("key")
        message.delete
        self.reason = "received confirmation email after #{duration} seconds"
        return OK
      end
    end

    self.reason = "did not receive confirmation email after #{duration} seconds"
    if duration >= limit
      return FAILED
    else
      run_again(period.seconds)
      return PENDING
    end
  end

end
