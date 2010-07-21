require 'net/http'
require 'uri'

class Fetch < Check
  def initialize(options = {})
    super({:url => "http://example.com/"}.merge(options))
  end

  def run
    url = URI.parse(self[:url])
    response = Net::HTTP.start(url.host, url.port) {|http|
      http.get(url.path)
    }
#    puts response.body
  end
end
