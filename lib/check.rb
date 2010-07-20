class Check
  attr_accessor :outcome, :reason

  def initialize(params = {})
    @outcome = :pending
    @reason = nil
    @params = {}
    params.each_pair do |key, value|
      self[key] = value # do them one at a time to get the symbol-to-string conversion
    end
  end

  def ok!
    @outcome = :ok
  end

  def failure!(reason = nil)
    @outcome = :failure
    @reason = reason.to_s if reason
    Exceptional::Catcher.handle(CheckFailed.new(to_s))
  end

  def run!
    begin
      run
      ok! if @outcome == :pending
    rescue Exception => e
      failure!(e)
    end
  end
  
  def run
    raise NotImplementedError
  end

  def params
    frozen_params = @params.dup
    frozen_params.instance_eval do
      def []=(key, value)
        raise "Sorry, but you can't modify the params object directly. Try check[#{key}]=#{value.inspect} instead."
      end
    end
    frozen_params
  end

  def [](key)
    @params[key.to_s]
  end

  def []=(key, value)
    @params[key.to_s] = value
  end

  def to_s
    [self.class.name, @reason, @params.inspect].compact.join(": ")
  end
end
