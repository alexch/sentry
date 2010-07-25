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
#
  def ok!
    self.outcome = Check::OK
  end

  def fail!(reason = nil)
    self.reason = reason.to_s if reason
    raise CheckFailed.new(to_s)
  end

  def run!
    begin
      self.outcome = run || Check::OK
    rescue Exception => e
      self.outcome = FAILED
      self.reason ||= e.to_s
      report_exception(e)
    end
    save
  end

  def run
    raise NotImplementedError, "Please implement #{self.class}#run"
  end

  # Note: we use a separate runner object to avoid a DJ bug:
  # http://github.com/collectiveidea/delayed_job/issues#issue/92
  # todo: test this object independently
  class Runner
    def initialize(check, time, method = nil)
      check.save if check.id.nil?
      @check_id = check.id
      @method = method || :run!
      Delayed::Job.enqueue(self, 0, time.from_now)
    end

    def perform
      check = Check.get(@check_id)
      if check.nil?
        logger.error("Couldn't find check##{@check_id.inspect}")
      else
        check.send @method
      end
    end
  end

  # todo: test (independently of countdown_spec)
  def run_in(time, method = nil)
    Runner.new(self, time, method)
  end

  #todo: run_at

  def to_s
    [self.class.name, self.reason, self.params.inspect].compact.join(": ")
  end
end
