class Check

  PENDING = "pending"
  OK = "ok"
  FAILED = "failed"

  include DataMapper::Resource

  property :id,         Serial
  property :type,       Discriminator
  property :created_at, DateTime
  property :outcome,    String, :length => 25
  property :reason,     Text
  property :params,     Object, :writer => :private

  def initialize(params = {})
    self.outcome = Check::PENDING
    self.reason = nil
    self.params = {}
    params.each_pair do |key, value|
      self[key] = value # do them one at a time to get the symbol-to-string conversion
    end
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

  def params
    frozen_params = attribute_get(:params).dup
    frozen_params.instance_eval do
      def []=(key, value)
        raise "Sorry, but you can't modify the params object directly. Try check[#{key}]=#{value.inspect} instead."
      end
    end
    frozen_params
  end

  def [](key)
    attribute_get(:params)[key.to_s]
  end

  def []=(key, value)
    attribute_get(:params)[key.to_s] = value
  end

  def to_s
    [self.class.name, self.reason, self.params.inspect].compact.join(": ")
  end
end
