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
        IC::logger.info "Received #{fresh.size} uuids"

        fresh.reject! { |uuid| sent?(uuid) }
        unless fresh.empty?
          result = fresh.sample
          fresh.delete result
          pool.merge fresh
          IC::logger.info "Fresh uuid selected, #{fresh.size} uuids added to pool"
          return result
        end

        pool.reject! { |uuid| sent?(uuid) }
        unless pool.empty?
          result = pool.to_a.sample
          pool.delete result
          IC::logger.info "Pool uuid selected, #{pool.size} uuids remain in pool"
          return result
        end

        nil
      end

      def pool
        @pool ||= load_pool
      end

      def sent
        @sent ||= load_sent
      end

      def save
        save_pool
        save_sent
        IC::logger.info "Saved pool=#{pool.size}, sent=#{sent.size}"
      end

      private

      def sent? uuid
        sent.has_key? uuid
      end

      def load_pool
        file = IC::CONFIG[:pool_file]
        data = JSON.parse File.read(file), symbolize_names: false
        raise "Invalid format of pool file" unless Array === data
        Set[*data]
      rescue
        Set::new
      end

      def load_sent
        file = IC::CONFIG[:sent_file]
        data = JSON.parse File.read(file), symbolize_names: false
        raise "Invalid format of sent file" unless Hash === data
        data
      rescue
        {}
      end

      def save_pool
        pool.reject! { |uuid| sent?(uuid) }
        file = IC::CONFIG[:pool_file]
        FileUtils.mkdir_p File.dirname(file)
        File.write file, JSON.pretty_generate(pool.to_a)
      end

      def save_sent
        file = IC::CONFIG[:sent_file]
        FileUtils.mkdir_p File.dirname(file)
        File.write file, JSON.pretty_generate(sent)
      end

    end

  end

end

module IC

  def select_uuid fresh
    INatChannel::Data::select_uuid fresh
  end

  def pool
    INatChannel::Data::pool
  end

  def sent
    INatChannel::Data::sent
  end

  def save_data
    INatChannel::Data::save
  end

  module_function :select_uuid, :pool, :sent, :save_data

end
