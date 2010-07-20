class Check
  attr_accessor :outcome

  def initialize
    @outcome = :pending
  end

  def success!
    @outcome = :success
  end

  def failure!
    @outcome = :failure
    Exceptional::Catcher.handle(CheckFailed.new(to_s))
  end

  def run
    raise NotImplementedError
  end
end
