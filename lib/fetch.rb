require "patron"

class Fetch < Check
  def initialize(options = {})
    super({:timeout => 10, :host => "example.com", :path => "/"}.merge(options))
  end

  def run
    session = Patron::Session.new
    session.timeout = self[:timeout]
    session.base_url = self[:host]
#    session.headers['User-Agent'] = 'myapp/1.0'
    begin
      response = session.get(self[:path])
    rescue Exception => e
      failure!(e)
    end
  end
end
