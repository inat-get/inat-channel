require 'time'
require 'json'
require 'fileutils'
require 'set'

require_relative 'config'
require_relative 'logger'
require_relative 'lock'

module INatChannel

  module Data 

    class << self

      def select_uuid fresh
        INatChannel::LOGGER.info "Received #{fresh.size} uuids"

        fresh.reject! { |uuid| sent?(uuid) }
        unless fresh.empty?
          result = fresh.sample
          fresh.delete result
          pool.merge fresh
          INatChannel::LOGGER.info "Fresh uuid selected, #{fresh.size} uuids added to pool"
          return result
        end

        pool.reject! { |uuid| sent?(uuid) }
        unless pool.empty?
          result = pool.sample
          pool.delete result
          INatChannel::LOGGER.info "Pool uuid selected, #{pool.size} uuids remain in pool"
          return result
        end

        nil
      end

      def save
        save_pool
        save_sent
        INatChannel::LOGGER.info "Saved pool=#{pool.size}, sent=#{sent.size}"
      end

      private

      def pool
        @pool ||= load_pool
      end

      def sent
        @sent ||= load_sent
      end

      def sent? uuid
        sent.has_key? uuid
      end

      def load_pool
        file = INatChannel::CONFIG[:pool_file]
        data = JSON.parse File.read(file), symbolize_names: false
        raise "Invalid format of pool file" unless Array === data
        Set[*data]
      rescue
        Set::new
      end

      def load_sent
        file = INatChannel::CONFIG[:sent_file]
        data = JSON.parse File.read(file), symbolize_names: false
        raise "Invalid format of sent file" unless Hash === data
        data
      rescue
        {}
      end

      def save_pool
        pool.reject! { |uuid| sent?(uuid) }
        file = INatChannel::CONFIG[:pool_file]
        FileUtils.mkdir_p File.dirname(file)
        File.write JSON.pretty_generate(pool.to_a)
      end

      def save_sent
        file = INatChannel::CONFIG[:sent_file]
        FileUtils.mkdir_p File.dirname(file)
        File.write JSON.pretty_generate(sent)
      end

    end

  end

end
