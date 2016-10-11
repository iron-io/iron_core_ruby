require File.expand_path('../lib/iron_core/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Andrew Kirilenko", "Iron.io, Inc"]
  gem.email         = ["info@iron.io"]
  gem.description   = "Core library for Iron products"
  gem.summary       = "Core library for Iron products"
  gem.homepage      = "https://github.com/iron-io/iron_core_ruby"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "iron_core"
  gem.require_paths = ["lib"]
  gem.version       = IronCore::VERSION

  gem.required_rubygems_version = ">= 1.3.6"
  gem.required_ruby_version = Gem::Requirement.new(">= 1.8")
  gem.add_runtime_dependency "rest", ">= 3.0.8"

  gem.add_development_dependency "test-unit"
  gem.add_development_dependency "minitest"
  gem.add_development_dependency "rake"

end
