# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "publisci"
  gem.homepage = "http://github.com/wstrinz/publisci"
  gem.license = "BSD 2-Clause"
  gem.summary = %Q{Publish scientific results to the semantic web}
  gem.description = %Q{A toolkit for publishing scientific results and datasets using RDF, OWL, and related technologies }
  gem.email = "wstrinz@gmail.com"
  gem.authors = ["Will Strinz"]
  gem.version = "0.1.3"

  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.rspec_opts = "--tag ~no_travis"
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end


require 'cucumber/rake/task'
Cucumber::Rake::Task.new(:features)

# task :default => :spec

task :default => [] do
  Rake::Task[:spec].invoke
end

task :test => [] do
  begin
    Rake::Task[:spec].invoke
  rescue
  end
  Rake::Task[:features].invoke
end

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : "0.0.1"

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "publisci #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
