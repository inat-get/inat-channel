require 'optparse'
require 'yaml'
require 'logger'

require_relative 'version'

module INatChannel

  module Config

    class << self

      def config
        @config ||= get_config.freeze
      end

      private

      def get_config
        options = parse_options
        options[:config] ||= './inat-channel.yml'
        cfg = load_config options[:config]
        cfg.merge! options
        cfg[:log_level] ||= :warn
        env = load_env
        cfg.merge! env
        validate_and_fix_config! cfg
        cfg
      end

      def parse_options
        options = {}
        OptionParser.new do |opts|
          opts.banner = 'Usage: inat-channel [options]'
          opts.on '-c', '--config FILE', 'Config file (default: inat-channel.yml)' do |v|
            raise "Config file not found: #{v}" unless File.exist?(v)
            options[:config] = v
          end
          opts.on '-l', '--log-level LEVEL', [:debug, :info, :warn, :error], 'Log level (default: warn)' do |v|
            options[:log_level] = v
          end
          opts.on '--debug', 'Set log level to debug' do
            options[:log_level] = :debug
          end
          opts.on '--version', 'Show version info and exit' do
            puts IC::VERSION
            exit
          end
          opts.on '-h', '--help', 'Show help and exit' do
            puts opts
            exit
          end
        end.parse!
        options
      end

      def load_config path
        raise "Config file not found: #{path}" unless File.exist?(path)
        cfg = YAML.safe_load_file path, symbolize_names: true
        if String === cfg[:places]
          path = File.expand_path(path)
          places_path = File.expand_path(cfg[:places], File.dirname(path))
          places = YAML.safe_load_file places_path, symbolize_names: true
          cfg[:places] = places
        end
        cfg
      end

      def load_env
        { 
          telegram_bot_token: (ENV['TELEGRAM_BOT_TOKEN'] or raise 'TELEGRAM_BOT_TOKEN required'),
          admin_telegram_id:  (ENV['ADMIN_TELEGRAM_ID']  or raise 'ADMIN_TELEGRAM_ID required')
        }
      end

      def validate_and_fix_config! cfg
        raise 'Missing or invalid base_query' unless Hash === cfg[:base_query]
        raise 'Missing or invalid days_back'  unless Integer === cfg[:days_back] && cfg[:days_back] > 0
        raise 'Missing chat_id'               unless cfg[:chat_id]

        basename = File.basename cfg[:config], '.*'
        cfg[:pool_file] ||= "./data/#{basename}_pool.json"
        cfg[:sent_file] ||= "./data/#{basename}_sent.json"
        cfg[:lock_file] ||= "./data/#{basename}__bot.lock"
        cfg[:retries]   ||= 5
      end

    end

  end

end

module IC

  CONFIG = INatChannel::Config::config

end

