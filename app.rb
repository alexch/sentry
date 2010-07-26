require "setup"
require "sinatra"

class SentryApp < Sinatra::Base
  configure :production do
    DataMapper::Logger.new($stdout, :debug)
  end

  configure do
    DataMapper.setup(:default, ENV['DATABASE_URL'] || 'sqlite3::memory:')

    # workaround for bug http://datamapper.lighthouseapp.com/projects/20609/tickets/1289-autoupgrades-fail-on-sti-models
    if ENV['DATABASE_URL']
      measure "Upgrading DB" do
        DataMapper.auto_upgrade!
      end
    else
      measure "Wiping DB" do
        DataMapper.auto_migrate!
      end
    end
  end

  get "/" do
    Main.new(:checks => Check.all).to_html
  end

  post "/check" do
    check_type = params["check_type"]
    check_class = check_type.constantize
    check = check_class.new(:params => params[check_type] || params["params"]) # lol
    logger.info "running #{check}"
    check.run!
    redirect "/"
  end

  get "/work" do
    x= capturing_output do
      Delayed::Job.all.each do |job|
        puts "invoking #{job.inspect}"
        job.invoke_job
        job.destroy
      end
#      Delayed::Worker.new.work_off  # this would do only the ones that need it
    end
    logger.info x
    redirect "/"
  end

  get "/sample" do
    checks = [
            Fetch.create(:params => {"url" => "http://notarealhost.foo"}),
            Fetch.create(:params => {:url => "http://google.com"}),
            Fetch.create(:params => {:url => "http://cohuman.com/home"}),
    ]
    measure "adding sample data" do
      checks.each do |check|
        capturing_output do
          check.run!
        end
      end
    end
    redirect "/"
  end
end
