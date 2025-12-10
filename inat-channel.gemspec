require_relative 'lib/inat-channel/version'

Gem::Specification::new do |s|
  s.name = 'inat-channel'
  s.version = INatChannel::VERSION
  s.summary = 'iNat Telegram Poster'
  s.description = 'iNaturalist Telegram Bot: Posts random popular observations from configurable API queries.'
  s.authors     = ["Ivan Shikhalev"]
  s.email       = ["shikhalev@gmail.com"]
  s.files       = Dir["{lib,bin}/**/*", "README.md", "LICENSE"]
  s.executables = Dir.children("bin")
  s.homepage    = "https://github.com/inat-get/inat-channel"
  s.license     = "GPL-3.0-or-later"

  s.required_ruby_version = "~> 3.4"

  s.add_dependency 'faraday', '~> 2.14'
  s.add_dependency 'faraday-retry', '~> 2.3'
  s.add_dependency 'sanitize', '~> 7.0'

  s.add_development_dependency "rspec", "~> 3.13"
  s.add_development_dependency "rake", "~> 13.3"
  s.add_development_dependency "simplecov", "~> 0.22.0"
  s.add_development_dependency "webmock", "~> 3.23"
  # s.add_development_dependency "tmpdir", "~> 0.3.1"  
  # s.add_development_dependency 'climate_control', '~> 1.2'
end
