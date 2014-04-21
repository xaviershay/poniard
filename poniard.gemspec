# -*- encoding: utf-8 -*-
require File.expand_path('../lib/poniard/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Xavier Shay"]
  gem.email         = ["contact@xaviershay.com"]
  gem.description   =
    %q{A dependency injector for Rails, allows you to write clean controllers.}
  gem.summary       =
    %q{A dependency injector for Rails, allows you to write clean controllers.}
  gem.homepage      = "http://github.com/xaviershay/poniard"

  gem.executables   = []
  gem.required_ruby_version = '>= 1.9.0'
  gem.files         = Dir.glob("{spec,lib}/**/*.rb") + %w(
                        README.md
                        CHANGELOG.md
                        LICENSE
                        poniard.gemspec
                      )
  gem.test_files    = Dir.glob("spec/**/*.rb")
  gem.name          = "poniard"
  gem.require_paths = ["lib"]
  gem.version       = Poniard::VERSION
  gem.has_rdoc      = false
end
