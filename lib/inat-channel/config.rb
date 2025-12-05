require 'optparse'
require 'yaml'
require 'logger'

module INatChannel

  attr_reader :config, :telegram_token, :notify_telegram_id, :logger

  def setup
    options = parse_options
    load_config(options[:config] || './inat-channel.yaml')
    load_env
    setup_logger(options[:log_level] || @config[:log_level] || :warn)
    validate_config
    acquire_lock!
    trap("INT") { release_lock; exit }
    trap("TERM") { release_lock; exit }
  end

  private

  def parse_options
    options = {}
    OptionParser.new do |opts|
      opts.banner = "Usage: inat-channel [options]"
      opts.on '-c', '--config FILE', 'Config file (default: inat-channel.yaml)' do |v| 
        options[:config] = v 
      end
      opts.on '-l', '--log-level LEVEL', [:debug, :info, :warn, :error], 'Log level (default: warn)' do |v| 
        options[:log_level] = v 
      end
      opts.on '--debug', 'Set log level to debug' do 
        options[:log_level] = :debug 
      end
      opts.on '-h', '--help', 'Show help' do 
        puts opts 
        exit 
      end
    end.parse!
    options
  end

  def load_config path
    raise "Config file not found: #{path}" unless File.exist?(path)
    @config = YAML.safe_load_file(path, symbolize_names: true).freeze
  end

  def load_env
    @telegram_token = ENV['TELEGRAM_BOT_TOKEN'].freeze or raise "TELEGRAM_BOT_TOKEN required"
    @notify_telegram_id = ENV['ADMIN_TELEGRAM_ID'].freeze or raise "ADMIN_TELEGRAM_ID required"
  end

  def setup_logger level
    @logger = Logger.new(STDOUT)
    @logger.level = Logger.const_get(level.to_s.upcase)
  end

  def validate_config
    required_keys = [:base_query, :days_back, :chat_id]
    # optional_keys = [:pool_file, :sent_file, :lock_file, :retries]          # unused
  
    missing = required_keys.reject { |k| @config.key?(k) }
    raise "Missing config keys: #{missing.join(', ')}" unless missing.empty?
  
    unless config[:days_back].is_a?(Integer) && config[:days_back] > 0
      raise "days_back must be positive integer"
    end
    unless config[:base_query].is_a?(Hash)
      raise "base_query must be a Hash"
    end
  end

end
