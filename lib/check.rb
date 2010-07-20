class Check
  attr_accessor :state

  def initialize
    @state = :pending
  end

  def success!
    @state = :success
  end

  def run
    raise NotImplementedError
  end
end
