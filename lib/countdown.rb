class Countdown < Check

  def run
    secs = param("sec").to_i
    if secs == 0
      Check::OK
    else
      save unless id
      secs -= 1
      param("sec", secs)
      run_in(1.second)
      Check::PENDING
    end
  end
end
