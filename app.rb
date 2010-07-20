require "setup"
require "sinatra"

class SentryApp < Sinatra::Base
  get "/" do
    "sentry"
  end
end
