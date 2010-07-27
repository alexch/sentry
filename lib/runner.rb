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

  def initialize(resource, method = nil)
    resource.save if resource.id.nil?
    @resource_class = resource.class
    @resource_id = resource.id
    @method = method || :perform
  end

  def resource
    @resource_class.get(@resource_id)
  end

  def perform
    if resource.nil?
      logger.error("Couldn't find resource##{@resource_id.inspect}")
    else
#      puts "Running #{@resource_class}##{@method}"
      resource.send @method
    end
  end
end
