require 'time'
require 'json'
require 'fileutils'

require_relative 'config'
require_relative 'logger'

module INatChannel

  module Lock

    class << self

      def acquire!
        file = INatChannel::CONFIG[:lock_file]
        FileUtils.mkdir_p File.dirname(file)

        if File.exist?(file)
          data = load_data file
          if stale?(data)
            INatChannel::LOGGER.info "Remove stale lock: #{file}"
            File.delete file
          else
            raise "Another instance is already running (PID: #{data[:pid]})"
          end
        end

        data = {
          pid: Process.pid,
          started_at: Time.now.utc.iso8601
        }
        File.write file, JSON.pretty_generate(data)
        INatChannel::LOGGER.info "Lock acquired: #{file}"
      end

      def release!
        file = INatChannel::CONFIG[:lock_file]
        return nil unless File.exist?(file)

        File.delete file
        INatChannel::LOGGER.info "Lock release: #{file}"
      end

      private

      def load_data file
        JSON.parse File.read(file), symbolize_names: true
      rescue 
        {}
      end

      LOCK_TTL = 1800  # 30 min

      def stale? data
        if data[:started_at]
          started_at = Time.parse data[:started_at]
          Time.now - started_at > LOCK_TTL
        else
          true
        end
      end

    end

    trap 'INT' do
      self.release!
      exit 130
    end

    trap 'TERM' do
      self.release!
      exit 143
    end

    at_exit do
      self.release!
    end

    acquire!

  end

end
