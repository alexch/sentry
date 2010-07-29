require "params"

class Check
  include DataMapper::Resource
  include Params
  include ExceptionReporting

  PENDING = "pending"
  OK = "ok"
  FAILED = "failed"

  property :id, Serial
  property :type, Discriminator
  property :created_at, DateTime
  property :outcome, String, :length => 25, :default => Check::PENDING
  property :reason, Text

  belongs_to :checker, :required => false

#  def initialize(attributes={}, & block)
#    attributes = defaults.merge(attributes.stringify_keys)
#    super(attributes, &block)
#  end

  def ok!
    self.outcome = Check::OK
  end

  def fail!(reason = nil)
    self.reason = reason.to_s if reason
    raise CheckFailed.new(to_s)
  end

  def run!
    measure "checking #{self}" do
      begin
        self.outcome = run || Check::OK
      rescue Exception => e
        self.outcome = FAILED
        self.reason ||= e.to_s
        report_exception(e)
        send_email(e)
      end
      save
    end
  end

  def send_email(exception)
    message = OutgoingMessage.new(:to => Email.all.map(&:address), :subject => "check failed",
      :body => self.to_s
    )
    message.deliver
  end

  def run
    raise NotImplementedError, "Please implement #{self.class}#run"
  end

  # todo: test (independently of countdown_spec)
  def run_again(time, method = :run!)
    Runner.enqueue(self, time, method)
  end

  #todo: run_at

  def to_s
    [self.class.name, self.reason, self.params.inspect].compact.join(": ")
  end
end
