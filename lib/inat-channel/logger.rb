require_relative 'config'

module INatChannel

  module Logger

    class << self

      def logger
        @logger ||= get_logger
      end

      private

      def get_logger
        lgr = ::Logger::new $stderr
        lgr.level = INatChannel::CONFIG[:log_level]
        lgr
      end

    end

  end

  LOGGER = Logger::logger

end

