require_relative 'lib/bluzelle/version'

Gem::Specification.new do |spec|
  spec.name          = "bluzelle"
  spec.version       = Bluzelle::VERSION
  spec.authors       = ["Mulenga Bowa"]
  spec.email         = ["mulengabowa53@gmail.com"]

  spec.summary       = "Ruby interface to the bluzelle service"
  spec.description   = "Ruby interface to the bluzelle service"
  spec.homepage      = "https://github.com/mul53/bluzelle"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/mul53/bluzelle"
  spec.metadata["changelog_uri"] = "https://github.com/mul53/bluzelle"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'bitcoin-ruby'
  spec.add_dependency 'money-tree'
  spec.add_dependency 'bip_mnemonic'
  spec.add_dependency 'openssl'
  spec.add_dependency 'rest-client'
end
