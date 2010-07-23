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
      DataMapper.auto_upgrade!
    else
      puts "Wiping DB..."
      DataMapper.auto_migrate!
      checks = [
              Fetch.create(:params => {"url" => "http://notarealhost.foo"}),
              Fetch.create(:params => {:url => "http://google.com"}),
              Fetch.create(:params => {:url => "http://cohuman.com/home"}),
      ]
      checks.each do |check|
        check.run!
      end
    end
  end

  get "/" do
    Main.new(:checks => Check.all).to_html
  end

  post "/check" do
    type = params[:type].constantize
    check = type.new(:params => params["params"]) # lol
    puts "running #{check}"
    check.run!
    redirect "/"
  end

  get "/work" do
    puts Delayed::Job.count
    x= capturing_output do
      Delayed::Job.all.each do |job|
        p job
        job.invoke_job
#        job.payload_object.perform
#        job.destroy
      end
#      Delayed::Worker.new.work_off
    end
    puts x
    redirect "/"
  end
end
