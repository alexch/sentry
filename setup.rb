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

Delayed::Worker.backend = :data_mapper

# Finalize all models after loading them.
# "This checks the models for validity and initializes all properties associated with relationships."
DataMapper.finalize
DataMapper::Model.raise_on_save_failure = true

# utility methods
def capturing_output
  output = StringIO.new
  $stdout = output
  yield
  output.string
ensure
  $stdout = STDOUT # STDOUT is the original output stream from when the Ruby interpreter was started
end
