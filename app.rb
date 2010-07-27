require "setup"
require "sinatra"

class SentryApp < Sinatra::Base
  set :app_file, __FILE__
  set :root, File.dirname(__FILE__)
  enable :method_override

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
    checks = Check.all(:order => [:created_at.desc])
    Main.new(:checks => checks).to_pretty
  end

  post "/check" do
    # this method is a bit confusing due to the two meanings of "params"
    check_type = params["check_type"]
    check_class = check_type.constantize
    check_params = params[check_type] || params["params"]

    if params[:schedule] && params[:schedule].to_i > 0
      checker = Checker.create(:check_type => check_type, :schedule => params[:schedule], :params => check_params)
      checker.perform
    else
      check = check_class.new(:params => check_params)
      check.run!
    end

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
    ]
    checkers = [
            Checker.create(:check_type => "Fetch", :params => {:url => "http://cohuman.com/home"}),
    ]
    measure "adding sample data" do
      checks.each do |check|
        capturing_output do
          check.run!
        end
      end
      checkers.each do |checker|
        capturing_output do
          # make a few, for history
          checker.perform
          checker.perform
        end
      end
    end
    redirect "/"
  end

  put "/cron" do
    Cron.summon.start
    redirect "/"
  end

  delete "/cron" do
    Cron.summon.stop
    redirect "/"
  end
end
