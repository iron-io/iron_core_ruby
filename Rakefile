require File.expand_path('../lib/3rdparty/facets/require_relative', __FILE__)

require 'rubygems'
require 'bundler'
require 'jeweler2'

Jeweler::Tasks.new do |gem|
  begin
    Bundler.setup(:default, :development)
  rescue Bundler::BundlerError => e
    $stderr.puts e.message
    $stderr.puts "Run `bundle install` to install missing gems"
    exit e.status_code
  end

  gem.name = "iron_core"
  gem.homepage = "https://github.com/iron-io/iron_core_ruby"
  gem.description = %Q{Core library for Iron products}
  gem.summary = %Q{Core library for Iron products}
  gem.email = "info@iron.io"
  gem.authors = ["Andrew Kirilenko", "Iron.io, Inc"]
  gem.files.exclude('.document', 'Gemfile', 'Gemfile.lock', 'Rakefile', 'iron_core.gemspec')
end

Jeweler::RubygemsDotOrgTasks.new
