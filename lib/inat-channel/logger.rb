require_relative 'facade'
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
        lgr.level = IC::CONFIG[:log_level]
        lgr
      end

    end

  end

end

module IC

  self >> INatChannel::Logger

  encapsulate INatChannel::Logger, :logger

end

