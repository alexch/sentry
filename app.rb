require "setup"
require "sinatra"

class SentryApp < Sinatra::Base
  get "/" do
    checks = [
            Fetch.new(:host => "google.com"),
            Fetch.new(:host => "cohuman.com/home")
    ]

    checks.each do |check|
      check.run!
    end
    Main.new(:checks => checks).to_html
  end
end
