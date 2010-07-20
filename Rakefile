require 'rubygems'
require 'bundler'
Bundler.setup :development

require 'rake'
require 'spec/rake/spectask'

here = File.expand_path(File.dirname(__FILE__))
require "#{here}/setup"

task :default => :spec

desc "run the app"
task :run do
  sh "rerun 'rackup -p 3000 config.ru'"
end

Spec::Rake::SpecTask.new do |spec|
  spec.spec_files = FileList['spec/**/*_spec.rb']
  spec.spec_opts = ['--backtrace']
end
