require 'net/http'
require 'uri'

class Fetch < Check
  def default_params
    super.merge({"url" => "http://example.com/"})
  end

  def parsed_url
    @parsed_url ||= URI.parse(self.param(:url))
  end

  def host
    parsed_url.host
  end

  def port
    parsed_url.port
  end

  def path
    parsed_url.path == "" ? "/" : parsed_url.path
  end

  def run
    response = Net::HTTP.start(host, port) {|http|
      http.get(path)
    }
#    puts response.body
    OK
  end
end
