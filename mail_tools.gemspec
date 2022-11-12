# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)
require_relative "lib/mail_tools/version"

Gem::Specification.new do |spec|
  spec.name          = "mail_tools"
  spec.version       = MailTools::VERSION
  spec.authors       = ["lisstem"]
  spec.email         = ["mail@lisstem.net"]

  spec.summary       = "Tools to set up and manage my mail servers"
  # spec.description   = 'TODO: Write a longer description or delete this line.'
  spec.homepage      = "https://git.lisstem.net/lisstem/mail-tools"
  spec.license       = "Nonstandard"
  spec.required_ruby_version = Gem::Requirement.new(">= 3.1.0")

  # spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  # spec.metadata['changelog_uri'] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", "~> 7.0"
  spec.add_dependency "bcrypt", "~> 3.1"
  spec.add_dependency "optimist", "~> 3.0"
  spec.add_dependency "pg", "~> 1.4"

  spec.add_development_dependency "guard", "~> 2.18"
  spec.add_development_dependency "guard-minitest", "~> 2.4"
  spec.add_development_dependency "minitest", "~> 5.16"
  spec.add_development_dependency "minitest-reporters", "~> 1.5"
  spec.add_development_dependency "mocha", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rubocop", "~> 1.38"
  spec.add_development_dependency "rubocop-minitest", "~> 0.23.0"
end
