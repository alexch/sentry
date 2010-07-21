class Countdown < Check
  def run
    secs = param("sec").to_i
    puts "secs=#{secs}"
    if secs == 0
      Check::OK
    else
      secs -= 1
      param("sec", secs)
      send_in 1, :run!
      puts "just queued up a send: #{Delayed::Job.count}"
      Check::PENDING
    end
  end
end
