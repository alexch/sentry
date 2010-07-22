def Kernel.environment
  begin
    RAILS_ENV
  rescue NameError, ArgumentError
    ENV['RAILS_ENV'] || ENV['RACK_ENV'] || "development"
  end.to_s
end

class Object
  def logger
    @@logger ||= Logger.new($stdout)
  end
  def logger=(logger)
    @@logger = logger
  end
end
