# Enqueues a DelayedJob to call a method on a DataMapper resource.
# Note: we use a separate runner object to avoid a DJ bug:
# http://github.com/collectiveidea/delayed_job/issues#issue/92
#
# todo: test this object independently
class Runner
  def initialize(resource, time, method = nil)
    resource.save if resource.id.nil?
    @resource_id = resource.id
    @method = method || :run!
    Delayed::Job.enqueue(self, 0, time.from_now)
  end

  def perform
    resource = Check.get(@resource_id)
    if resource.nil?
      logger.error("Couldn't find resource##{@resource_id.inspect}")
    else
      resource.send @method
    end
  end
end
