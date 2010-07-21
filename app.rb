require "setup"
require "sinatra"

class SentryApp < Sinatra::Base
  get "/" do
    checks = [
            Fetch.new(:url => "http://notarealhost.foo"),
            Fetch.new(:url => "http://google.com"),
            Fetch.new(:url => "http://cohuman.com/home")
    ]

    checks.each do |check|
      check.run!
    end
    Main.new(:checks => checks).to_html
  end
end
