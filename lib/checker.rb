class Checker
  class UnsavedChecker < RuntimeError
  end

  include DataMapper::Resource
  include Params

  property :id, Serial
  property :check_type, String, :required => true
  property :schedule, Integer, :required => true, :default => 1

  has n, :checks, :order => [ :created_at.desc ]

  def perform
    raise UnsavedChecker if new?
    check = check_class.create(:params => params, :checker => self)
    checks << check
    check.run!
    check
  end

  def last_run_at
    checks.first && checks.first.created_at
  end

  def next_run_at
    if last_run_at.nil?
      Time.now.to_datetime
    else
      (last_run_at + schedule.minutes).to_datetime
    end
  end

  def check_class
    check_type.constantize
  end
end
