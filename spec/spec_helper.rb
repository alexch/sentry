here = File.expand_path(File.dirname(__FILE__))
require File.expand_path("#{here}/../setup")
require 'spec'
require "sinatra"
require "logger"

ENV['RACK_ENV'] = ENV['RAILS_ENV'] =  'test'

DataMapper::Logger.new(Pathname.new("#{ROOT}/log/test.log"), :debug)
DataMapper.setup(:default, 'sqlite::memory:')
#require "dm-core/adapters/in_memory_adapter"
#DataMapper.setup(:default, :adapter => :in_memory)
DataMapper.auto_migrate!

Object.logger = Logger.new(File.open('log/test.log', File::WRONLY | File::APPEND | File::CREAT))

Spec::Runner.configure do |config|

  class SentryApp < Sinatra::Base
    set :environment, :test
  end

  config.before(:each) do
    OutgoingMessage.fake
  end

  config.after(:each) do

  end
end

# thanks http://erikonrails.snowedin.net/?p=230
module DelayedJobSpecHelper
  def work_off
    Delayed::Job.all.each do |job|
#      puts "Running job #{job.id} on #{job.payload_object.inspect}"
      job.payload_object.perform
      job.destroy
    end
  end
end

# sample check classes, for testing
class Win < Check
  def run
    # no news is good news
  end
end

class Lose < Check
  def run
    raise "FTL"
  end
end

class Draw < Check
  def run
    Check::PENDING
  end
end

class Fail < Check
  def run
    fail! "epic fail"
  end
end

class Echo < Check
  def run
    puts param("message")
  end
end
