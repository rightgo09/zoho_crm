# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'zoho_crm/version'

Gem::Specification.new do |spec|
  spec.name          = "zoho_crm"
  spec.version       = ZohoCrm::VERSION
  spec.authors       = ["rightgo09"]
  spec.email         = ["skyarrow09@gmail.com"]
  spec.summary       = %q{Zoho CRM gem}
  spec.description   = %q{Read data in Zoho CRM by using API.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "httparty", "~> 0.13.0"
  spec.add_runtime_dependency "oj", "~> 2.6.0"
  spec.add_runtime_dependency "activesupport", "~> 4.0.3"
  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake", "< 11.0"
  spec.add_development_dependency "rspec", "~> 2.14.1"
  spec.add_development_dependency "simplecov", '~> 0.7.1'
  spec.add_development_dependency "coveralls", "~> 0.7.0"
end
