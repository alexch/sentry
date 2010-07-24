require 'exceptional'

module Environment
  def environment
    begin
      RAILS_ENV
    rescue NameError, ArgumentError
      ENV['RAILS_ENV'] || ENV['RACK_ENV'] || "development"
    end.to_s
  end
end

module ExceptionReporting
  include Environment
  
  def report_exception(exception, request = nil)
    begin
      if exception.is_a? String
        # turn string into an exception (with stack trace etc.)
        begin
          raise exception
        rescue RuntimeError => raised_exception
          exception = raised_exception
        end
      end

      if ['test', 'development'].include? Kernel.environment
        puts "Reporting Exception: #{exception.class}: #{exception.message}"
        puts "\t" + exception.backtrace.join("\n\t")
      end

      if request
        Exceptional::Catcher.handle_with_rack(exception, request.env, request)
      else
        Exceptional::Catcher.handle(exception)
      end
    rescue Exception => exceptional_error
      logger.error "#{exceptional_error.class}: #{exceptional_error.message}"
      logger.error "\t" + exceptional_error.backtrace.join("\n\t")
    end
  end
end
