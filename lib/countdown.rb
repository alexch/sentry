class Countdown < Check
  def self.description
    "Decrement a counter once per second (or so). Used to verify that background jobs are working."
  end

  def default_params
    super.merge(:sec => 10)
  end

  def run
    secs = param("sec").to_i
    if secs == 0
      Check::OK
    else
      save unless id
      secs -= 1
      param("sec", secs)
      run_again(1.second)
      Check::PENDING
    end
  end
end
