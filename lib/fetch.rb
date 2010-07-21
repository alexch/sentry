require 'net/http'
require 'uri'

class Fetch < Check
  def initialize(options = {})
    super({:url => "http://example.com/"}.merge(options))
  end

  def url
    @url ||= URI.parse(self[:url])
  end

  def host
    url.host
  end

  def port
    url.port
  end

  def path
    url.path == "" ? "/" : url.path
  end

  def run
    response = Net::HTTP.start(host, port) {|http|
      http.get(path)
    }
#    puts response.body
  end
end
