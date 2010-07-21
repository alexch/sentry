require "setup"
require "sinatra"

class SentryApp < Sinatra::Base
  configure do
    DataMapper::Logger.new($stdout, :debug)
    DataMapper.setup(:default, ENV['DATABASE_URL'] || 'sqlite3://sentry_test.db')
    # workaround for bug http://datamapper.lighthouseapp.com/projects/20609/tickets/1289-autoupgrades-fail-on-sti-models
    if ENV['DATABASE_URL']
      DataMapper.auto_upgrade!
    else
      puts "Auto migrating"
      DataMapper.auto_migrate!
      checks = [
              Fetch.create(:url => "http://notarealhost.foo"),
              Fetch.create(:url => "http://google.com"),
              Fetch.create(:url => "http://cohuman.com/home"),
      ]
      checks.each do |check|
        check.run!
      end
    end
  end

  get "/" do
    checks = Check.all
    Main.new(:checks => checks).to_html
  end
end
