class Checker
  class UnsavedChecker < RuntimeError
  end

  include DataMapper::Resource
  include Params

  property :id, Serial
  property :check_type, String, :required => true

  has n, :checks, :order => [ :created_at.desc ]

  def run_check
    raise UnsavedChecker if new?
    check = check_class.new(:params => params, :checker => self)
    checks << check
    check
  end

  protected
  def check_class
    check_type.constantize
  end
end
