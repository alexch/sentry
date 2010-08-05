unless Object.const_defined? :ROOT

  ROOT = File.expand_path(File.dirname(__FILE__))
  $:.unshift ROOT
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

  require "lib/useful" # monkey patches and utility methods
  capturing_stderr do
    require "json/pure" # required to avoid NoMethodError - undefined method `generate' for JSON::Ext::Generator::State
  end

  env = Pathname.new "#{ROOT}/config/env.rb"
  if File.exist? env
    load env
  end

  ROOT_DIRS = ["lib", "domain", "views"]

#  require "lib/exception_reporting"

# pre-require files underneath source root directories
  ROOT_DIRS.each do |dir|
    $:.unshift "#{ROOT}/#{dir}"
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


end
