module Measure
  def measure_dec(x)
    "%02d" % (x.to_f % 1 * 100)
  end

  def measure_say(msg)
    log = respond_to?(:logger) ? logger : Logger.new($stdout)
    now = Time.now
    log.info("#{now.strftime('%H:%M:%S')}.#{measure_dec(now)} #{msg}")
  end

  def measure(name)
    start = Time.now
    measure_say "--> starting #{name} from #{caller[1]}:#{caller[2]}"
    result = yield
    finish = Time.now
    duration = (finish - start)
    measure_say "--< finished #{name} --- #{"%2.3f sec" % (duration)}"
    result
  end

end
