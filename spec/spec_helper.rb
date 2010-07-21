here = File.expand_path(File.dirname(__FILE__))
require File.expand_path("#{here}/../setup")
require 'spec'
require "sinatra"

ENV['RACK_ENV'] = ENV['RAILS_ENV'] =  'test'

DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, 'sqlite::memory:')
DataMapper.auto_migrate!

Spec::Runner.configure do |config|

  class SentryApp < Sinatra::Base
    set :environment, :test
  end

#  require 'app'

  config.before(:each) do
#    OutgoingMessage.fake
#    DB.setup  # start transaction
  end

  config.after(:each) do
#    DB.teardown  # rollback transaction
  end
end
