unless Object.const_defined? :ROOT
ROOT = File.expand_path(File.dirname(__FILE__))
$:.unshift ROOT
$:.unshift "#{ROOT}/lib"
Dir.chdir(ROOT)

require 'rubygems'
require 'bundler'
Bundler.setup

require 'dm-core'
require 'dm-migrations'
require 'dm-timestamps'
require 'dm-validations'
require 'dm-types/json'
require 'exceptional'
require 'erector'
require "delayed_job"

# class aliases
Widget = Erector::Widget

# Thanks http://jacobrothstein.com/delayed-job-send-later-with-run-at
class Object
  def send_in(time, method, *args)
    send_at time.from_now, method, *args
  end

  def send_at(time, method, *args)
    Delayed::Job.enqueue Delayed::PerformableMethod.new(self, method.to_sym, args), 0, time
  end
end

env = Pathname.new "#{ROOT}/config/env.rb"
if File.exist? env
  load env
end

ROOT_DIRS = ["lib", "views"]

require "lib/exception_reporting"

# pre-require files underneath source root directories
ROOT_DIRS.each do |dir|
  Dir["#{dir}/**/*.rb"].sort.each do |file|
    require file
  end
end

  include Measure

Delayed::Worker.backend = :data_mapper

# Finalize all models after loading them.
# "This checks the models for validity and initializes all properties associated with relationships."
DataMapper.finalize
DataMapper::Model.raise_on_save_failure = true


# utility methods
def capturing_output
  original_stdout = $stdout
  $stdout = StringIO.new
  yield
  $stdout.string
ensure
  $stdout = original_stdout
end

  # workaround for activesupport vs. json_pure vs. Ruby 1.8 glitch
  if JSON.const_defined?(:Pure)
    class JSON::Pure::Generator::State
      include ActiveSupport::CoreExtensions::Hash::Except
    end
  end

end
