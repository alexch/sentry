# Enqueues a DelayedJob to call a method on a DataMapper resource.
# Note: we use a separate runner object to avoid a DJ bug:
# http://github.com/collectiveidea/delayed_job/issues#issue/92
#
# todo: test this object independently
class Runner

  def self.enqueue(resource, time = 0, method = nil)
    runner = Runner.new(resource, method)
    Delayed::Job.enqueue(runner, 0, time.from_now)
  end

  attr_reader :method_name

  def initialize(resource, method = nil)
    resource.save if resource.id.nil?
    @resource_class_name = resource.class.name
    @resource_id = resource.id
    @method_name = method || :perform
  end

  def resource
    @resource_class_name.constantize.get(@resource_id)
  end

  def perform
    if resource.nil?
      logger.error("Couldn't find resource##{@resource_id.inspect}")
    else
#      puts "Running #{@resource_class}##{@method_name}"
      resource.send @method_name
    end
  end
end
