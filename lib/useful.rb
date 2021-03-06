# class aliases
Widget = Erector::Widget

# todo: test, move into Erector maybe
class Widget
  def form(attrs)
    attrs = Mash.new(attrs)
    method = attrs[:method].to_s.downcase
    real_method = case method
                    when "post", "get"
                      method
                    else
                      "post"
                  end
    attrs[:method] = real_method
    element(:form, attrs) do
      input :type => "hidden", :name => "_method", :value => method unless method == real_method
      yield
    end
  end
end

# Thanks http://jacobrothstein.com/delayed-job-send-later-with-run-at
class Object
  def send_in(time, method, *args)
    send_at time.from_now, method, *args
  end

  def send_at(time, method, *args)
    Delayed::Job.enqueue Delayed::PerformableMethod.new(self, method.to_sym, args), 0, time
  end
end

# utility methods
def capturing_output
  original = $stdout
  captured = StringIO.new
  $stdout = captured
  yield
  captured.string
ensure
  # allow nesting
  if original.is_a? StringIO
    original << captured.string
  end
  $stdout = original
end

def capturing_stderr
  original = $stderr
  captured = StringIO.new
  $stderr = captured
  yield
  captured.string
ensure
  # allow nesting
  if original.is_a? StringIO
    original << captured.string
  end
  $stderr = original
end

# workaround for activesupport vs. json_pure vs. Ruby 1.8 glitch
if JSON.const_defined?(:Pure)
  class JSON::Pure::Generator::State
    include ActiveSupport::CoreExtensions::Hash::Except
  end
end

# todo: fix in Erector
class ExternalRenderer < Erector::Widget
  def inline_scripts
    rendered_externals(:script).each do |external|
      javascript external.options do
        rawtext external.text
      end
    end
    rendered_externals(:jquery).each do |external|
      jquery :load, external.text, external.options
    end
    rendered_externals(:jquery_ready).each do |external|
      jquery :ready, external.text, external.options
    end
  end
end

