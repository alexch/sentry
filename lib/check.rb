class Check
  include ExceptionReporting

  PENDING = "pending"
  OK = "ok"
  FAILED = "failed"

  include DataMapper::Resource

  property :id, Serial
  property :type, Discriminator
  property :created_at, DateTime
  property :outcome, String, :length => 25
  property :reason, Text
  property :params, Object

  def convert_to_string_keys(hash)
    out = {}
    hash.each_pair do |key, value|
      # do them one at a time to get symbol-to-string conversion
      out[key.to_s] = value
    end
    out
  end

  def defaults
    {:outcome => Check::PENDING}
  end

  def default_params
    {}
  end

  def initialize(attributes={}, & block)
    attributes = defaults.merge(convert_to_string_keys(attributes))
    attributes["params"] = default_params.merge(convert_to_string_keys(attributes["params"] || {}))
    super(attributes, &block)
  end

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

#  def params
#    frozen_params = attribute_get(:params).dup
#    frozen_params.instance_eval do
#      def []=(key, value)
#        raise "Sorry, but you can't modify the params object directly. Try check[#{key}]=#{value.inspect} instead."
#      end
#    end
#    frozen_params
#  end

  def param(* args)
    if args.length == 2
      key, value = args
      new_params = attribute_get(:params).dup # need to dup so DM knows it's dirty
      new_params[key.to_s] = value
      attribute_set(:params, new_params)
    elsif args.length == 1
      key = args.first
      attribute_get(:params)[key.to_s]
    else
      raise ArgumentError, "param takes either one (for get) or two (for set) arguments"
    end
  end

  def set(key, value)
  end

  def to_s
    [self.class.name, self.reason, self.params.inspect].compact.join(": ")
  end
end
