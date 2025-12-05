Gem::Specification::new do |s|
  s.name = 'inat-channel'
  s.version = '0.8.0.2'
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

  s.add_development_dependency "rspec", "~> 3.13"
  s.add_development_dependency "rake", "~> 13.3"
  s.add_development_dependency "simplecov", "~> 0.22.0"
end
