unless Object.const_defined? :ROOT
ROOT = File.expand_path(File.dirname(__FILE__))
$:.unshift ROOT
$:.unshift "#{ROOT}/lib"
Dir.chdir(ROOT)

unless Object.const_defined?(:Bundler)
  require 'rubygems'
  require 'bundler'
end
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
  original = $stdout
  captured = StringIO.new
  $stdout = captured
  yield
  captured.string
ensure
  # allow nesting
  if original.is_a? StringIO
    original << captured.string
  end
  $stdout = original
end

  # workaround for activesupport vs. json_pure vs. Ruby 1.8 glitch
  if JSON.const_defined?(:Pure)
    class JSON::Pure::Generator::State
      include ActiveSupport::CoreExtensions::Hash::Except
    end
  end

  # todo: fix in Erector
  class ExternalRenderer < Erector::Widget
    def inline_scripts
      rendered_externals(:script).each do |external|
        javascript external.options do
          rawtext external.text
        end
      end
      rendered_externals(:jquery).each do |external|
        jquery :load, external.text, external.options
      end
      rendered_externals(:jquery_ready).each do |external|
        jquery :ready, external.text, external.options
      end
    end
  end


end
