require 'simplecov'
SimpleCov.start { add_filter '/spec/' }
require 'rspec'
require 'fileutils'
require 'yaml'

File.delete('./inat-channel.yml') rescue nil

$original_argv = ARGV.dup
ARGV.clear

ENV['TELEGRAM_BOT_TOKEN'] = 'test_token'
ENV['ADMIN_TELEGRAM_ID'] = '12345'

test_config = {
  'base_query' => { 'project_id' => 99999 },
  'days_back' => { 'fresh' => 30 },
  'tg_bot' => { 'chat_id' => -1001234567890 }
}
FileUtils.mkdir_p('spec/tmp')
File.write('spec/tmp/inat-channel.yml', YAML.dump(test_config))
File.symlink('spec/tmp/inat-channel.yml', './inat-channel.yml')

require_relative '../lib/inat-channel'
File.delete('./inat-channel.yml')

RSpec.configure do |config|
  config.expect_with(:rspec) do |expectations|
    expectations.syntax = :expect
  end

  config.mock_with(:rspec) do |mocks|
    mocks.syntax = :rspec
  end

  config.after(:suite) do
    FileUtils.rm_rf('spec/tmp')
  end
end
