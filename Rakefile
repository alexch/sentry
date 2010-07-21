require 'rubygems'
require 'bundler'
Bundler.setup :default, :development

require 'rake'
require 'spec/rake/spectask'
require 'delayed/tasks'

here = File.expand_path(File.dirname(__FILE__))
require "#{here}/setup"

task :default => :spec

desc "run the app"
task :run do
  sh "rerun 'rackup -p 3000 config.ru'"
end

Spec::Rake::SpecTask.new do |spec|
  spec.spec_files = FileList['spec/**/*_spec.rb']
#  spec.spec_opts = ['--backtrace']
end

task :setup_app do
  DataMapper.setup(:default, 'sqlite:///db/sentry_dev.db')
end

namespace :jobs do
  task :work => :setup_app
  task :clear => :setup_app
end

