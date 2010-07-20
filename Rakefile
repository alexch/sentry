require 'rubygems'
require 'bundler'
Bundler.setup :development

require 'rake'
require 'spec/rake/spectask'

require "setup"

desc "run the app"
task :run do
  sh "rerun 'rackup -p 3000 config.ru'"
end

Spec::Rake::SpecTask.new do |spec|
  spec.spec_files = FileList['spec/**/*_spec.rb']
  spec.spec_opts = ['--backtrace']
end
