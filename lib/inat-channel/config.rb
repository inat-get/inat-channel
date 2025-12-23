require 'optparse'
require 'yaml'
require 'logger'

require_relative 'facade'
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
        cfg[:tg_bot] ||= {}
        cfg[:tg_bot].merge! env
        validate_and_fix_config! cfg
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
          token:    (ENV['TELEGRAM_BOT_TOKEN'] or raise 'TELEGRAM_BOT_TOKEN required'),
          admin_id: (ENV['ADMIN_TELEGRAM_ID']  or raise 'ADMIN_TELEGRAM_ID required')
        }
      end

      def validate_and_fix_config! cfg
        raise 'Missing or invalid base_query' unless Hash === cfg[:base_query]
        raise 'Missing or invalid days_back'  unless Integer === cfg.dig(:days_back, :fresh) && cfg.dig(:days_back, :fresh)
        raise 'Missing chat_id'               unless cfg.dig(:tg_bot, :chat_id)

        basename = File.basename cfg[:config], '.*'
        cfg[:data_files]        ||= {}
        cfg[:data_files][:root] ||= 'data'
        cfg[:data_files][:pool] ||= "#{ cfg[:data_files][:root] }/#{ basename }_pool.json"
        cfg[:data_files][:sent] ||= "#{ cfg[:data_files][:root] }/#{ basename }_sent.json"
        cfg[:data_files][:used] ||= "#{ cfg[:data_files][:root] }/#{ basename }_used.json"

        cfg[:lock_file]        ||= {}
        cfg[:lock_file][:path] ||= "#{ cfg[:data_files][:root] }/#{ basename }__bot.lock"
        cfg[:lock_file][:ttl]  ||= 300  # 5 min

        cfg[:days_back][:pool] ||= 3 * cfg.dig(:days_back, :fresh)
        cfg[:days_back][:sent] ||= cfg[:days_back][:pool] + 1
        cfg[:days_back][:used] ||= 365

        cfg[:api]              ||= {}
        cfg[:api][:retries]    ||= 5
        cfg[:api][:interval]   ||= 1.0
        cfg[:api][:randomness] ||= 0.5
        cfg[:api][:backoff]    ||= 2
        cfg[:api][:page_delay] ||= 1.0
        cfg[:api][:per_page]   ||= 200

        cfg[:tg_bot][:retries]    ||= 5
        cfg[:tg_bot][:interval]   ||= 1.0
        cfg[:tg_bot][:randomness] ||= 0.5
        cfg[:tg_bot][:backoff]    ||= 2
        cfg[:tg_bot][:desc_limit] ||= 512
        cfg[:tg_bot][:link_zoom]  ||= 12

        cfg[:unique_taxon] ||= :ignore
        cfg[:unique_taxon]   = cfg[:unique_taxon].to_sym

        cfg[:log_level]    ||= :warn
        cfg[:log_level]      = cfg[:log_level].to_sym
        cfg[:notify_level] ||= :warn
        cfg[:notify_level]   = cfg[:notify_level].to_sym

        cfg
      end

    end

    CONFIG = self.config

  end

end

module IC

  self >> INatChannel::Config

  encapsulate INatChannel::Config, :CONFIG

end
