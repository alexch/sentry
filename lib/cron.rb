require "delayed_job"

class Cron
  include DataMapper::Resource
  property :id, Serial
#  belongs_to :job, :model => ::Delayed::Job  # got a chicken-and-egg problem here
  property :job_id, Integer

  def self.summon
    Cron.first_or_create
  end

  def job
    Delayed::Job.get(job_id) if job_id
  end

  def job=(j)
    self.job_id=j.id
  end

  def runnable_checkers
    # todo: denormalize next_run_at or put it into SQL, for optimization
    checkers = Checker.all.select do |checker|
      checker.next_run_at <= Time.now
    end
    checkers
  end

  def perform
    runnable_checkers.each do |checker|
      logger.info "Cron enqueuing #{checker.inspect}"
      Runner.enqueue(checker)
    end
    schedule
  end

  def schedule
    job = Runner.enqueue(self, 1.minute)
    self.job_id = job.id
    save
    job
  end

  def start
    unless job
      perform
    end
    job
  end

  def stop
    if job
      # todo: be smart if the job is currently running
      if job.locked_at
        logger.warning("Job #{job_id} is locked")
      end
      job.destroy
      self.job_id = nil
      save
    end
  end

end
