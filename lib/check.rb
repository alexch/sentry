class Check

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

  def failure!(reason = nil)
    self.outcome = FAILED
    self.reason = reason.to_s if reason
    Exceptional::Catcher.handle(CheckFailed.new(to_s))
  end

  def run!
    begin
      run
      ok! if self.outcome == Check::PENDING
    rescue Exception => e
      failure!(e)
    end
    save
  end

  def run
    raise NotImplementedError
  end

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
      x = attribute_get(:params)
      x[key.to_s] = value
      attribute_set(:params, x)
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
