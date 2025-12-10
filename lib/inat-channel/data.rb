require 'time'
require 'date'
require 'json'
require 'fileutils'
require 'set'

require_relative 'config'
require_relative 'logger'
require_relative 'lock'

module INatChannel

  module Storage

    class << self

      def select_uuid fresh
        # 1. Отфильтровываем уже отправленные
        fresh.reject! { |rec| sent?(rec[:uuid]) }

        # 2. Если нужно, отфильтровываем по таксонам
        taxon_uniq = IC::CONFIG[:taxon_uniq]            # :string эквивалентно бесконечному целому
        fresh.reject! { |rec| used?(rec.dig :taxon, :id) } if taxon_uniq == :strict || Integer === taxon_uniq
        
        if taxon_uniq == :priority
          uniq_fresh = fresh.reject { |rec| used?(rec.dig :taxon, :id) }
          unless uniq_fresh.empty?
            IC::logger.info "Take a fresh & unique (from #{uniq_fresh.size})"
            sample = sample_with_weight uniq_fresh, field: :faves_count
            fresh.reject { |rec| rec[:uuid] == sample[:uuid] }.each do |rec| 
              pool[rec[:uuid]] = {
                'created_at' => Date.parse(rec[:created_at]),
                'faves_count' => rec[:faves_count],
                'taxon_id' => rec.dig(:taxon, :id)
              }
            end
            sample[:taxon_id] = sample.dig :taxon, :id
            @in_process = sample
            return sample[:uuid]
          end
        end

        # 3. Если добрались до этого места, берем просто из свежих
        unless fresh.empty?
          IC::logger.info "Take a fresh (from #{fresh.size})"
          sample = sample_with_weight fresh, field: :faves_count
          fresh.reject { |rec| rec[:uuid] == sample[:uuid] }.each do |rec|
            pool[rec[:uuid]] = {
              "created_at" => Date.parse(rec[:created_at]),
              "faves_count" => rec[:faves_count],
              "taxon_id" => rec.dig(:taxon, :id),
            }
          end
          sample[:taxon_id] = sample.dig :taxon, :id
          @in_process = sample
          return sample[:uuid]
        end
        
        # 4. Если ..., проверяем приоритет уникальных уже для пула
        pool_records = pool.map { |k, v| v.merge({ 'uuid' => k }) }
        if taxon_uniq == :priority
          uniq_pool = pool_records.reject { |rec| used?(rec['taxon_id']) }
          unless uniq_pool.empty?
            IC::logger.info "Take an unique pool record (from #{uniq_pool.size})"
            sample = sample_with_weight uniq_pool, field: 'faves_count'
            sample.transform_keys!(&:to_sym)
            @in_process = sample
            return sample[:uuid]
          end
        end

        # 5. Если ..., берем из пула
        unless pool_records.empty?
          IC::logger.info "Take a pool record (from #{pool.size})"
          sample = sample_with_weight pool_records, field: 'faves_count'
          sample.transform_keys!(&:to_sym)
          @in_process = sample
          return sample[:uuid]
        end

        return nil
      end

      def confirm! msg_id
        # Отправка выполнена, фиксируем
        sent[@in_process[:uuid]] = {
          'msg_id' => msg_id,
          'sent_at' => Date.today
        }
        used[@in_process[:taxon_id]] = Date.today
      end

      def revert!
        # Отправка не выполнена, возвращаем рабочую запись в пул
        pool[@in_process[:uuid]] = {
          'created_at' => @in_process[:created_at],
          'faves_count' => @in_process[:faves_count],
          'taxon_id' => @in_process[:taxon_id]
        }
      end

      def save
        save_pool
        save_sent
        save_used
        IC::logger.info "Saved pool=#{pool.size}, sent=#{sent.size}"
      end

      private

      def used
        @used ||= load_used
      end

      def pool
        @pool ||= load_pool
      end

      def sent
        @sent ||= load_sent
      end

      def sent? uuid
        sent.has_key? uuid
      end

      def used? taxon_id
        used.has_key? taxon_id
      end

      def sample_with_weight source, field: 
        data = []
        source.each do |rec|
          num = rec[field]
          num = 1 unless Integer === num && num > 0
          num.times { data << rec }
        end
        data.sample
      end

      def reload_pool old
        result = {}
        old.each_slice 100 do |items|
          records = IC::load_list uuid: items.join(',')
          records.each do |rec|
            result[rec[:uuid]] = {
              'created_at' => Date.parse(rec[:created_at]),
              'faves_count' => rec[:faves_count],
              'taxon_id' => rec.dig(:taxon, :id)
            }
          end
        end
        result
      end

      def fetch_new_pool
        result = {}
        dead_date = Date.today - IC::CONFIG[:pool_depth]
        records = IC::load_list(**IC::CONFIG[:base_query], created_d1: dead_date.to_s)
        records.each do |rec|
          result[rec[:uuid]] = {
            'created_at' => Date.parse(rec[:created_at]),
            'faves_count' => rec[:faves_count],
            'taxon_id' => rec.dig(:taxon, :id)
          }
        end
        result
      end

      def load_pool
        file = IC::CONFIG[:pool_file]
        if File.exist?(file)
          data = JSON.parse File.read(file), symbolize_names: false
          case data
          when Hash
            data.each do |_, value|
              begin
                value['created_at'] = Date.parse(value['created_at'])
              rescue => e
                IC::logger.error "Error in pool: #{e.message}"
                IC::logger.debug "Value: #{value.inspect}"
                value['created_at'] = Date.today
              end
            end
            data
          when Array
            IC::logger.warn "❗ Old format of pool ❗"
            IC::notify_admin "❗ Old format of pool ❗"
            reload_pool data
          else
            IC::notify_admin "❌ Unknown format of pool"
            raise "❌ Unknown format of pool"
          end
        else
          fetch_new_pool
        end
      rescue => e
        IC::notify_admin '❌ ' + e.message
        raise e
      end

      def load_used
        file = IC::CONFIG[:used_file]
        if File.exist?(file)
          data = JSON.parse File.read(file), symbolize_names: false
          data.transform_keys!(&:to_i)
          data.transform_values! do |value|
            begin
              Date.parse value
            rescue => e
              IC::logger.error "Error in used: #{e.message}"
              IC::logger.debug "Value: #{value.inspect}"
              Date.today
            end
          end
          data
        else
          {}
        end
      rescue => e
        IC::notify_admin '❌ ' + e.message
        raise e
      end

      def load_sent
        file = IC::CONFIG[:sent_file]
        if File.exist?(file)
          data = JSON.parse File.read(file), symbolize_names: false
          raise "Invalid format of sent file" unless Hash === data
          # Чистим чего набажили...
          data.each do |_, value|
            begin
              value['sent_at'] = Date.parse(value['sent_at'])
            rescue => e
              IC::logger.error "Error in sent: #{e.message}"
              IC::logger.debug "Value: #{value.inspect}"
              value['sent_at'] = Date.today
            end
          end
          data
        else
          {}
        end
      rescue => e
        IC::notify_admin '❌ ' + e.message
        raise e
      end

      def save_pool
        size = pool.size

        # 1. Удаляем отправленные
        pool.reject! { |uuid, _| sent?(uuid) }
        IC::logger.info "Removed #{size - pool.size} sent records from pool" if pool.size != size
        size = pool.size

        # 2. Удаляем использованные
        taxon_uniq = IC::CONFIG[:taxon_uniq]
        pool.reject! { |_, value| used?(value['taxon_id']) } if taxon_uniq == :strict || Integer === taxon_uniq
        IC::logger.info "Removed #{size - pool.size} used records from pool" if pool.size != size
        size = pool.size

        # 3. Удаляем устаревшие
        dead_date = Date.today - IC::CONFIG[:pool_depth]
        pool.reject! { |_, value| value['created_at'] < dead_date }
        IC::logger.info "Removed #{size - pool.size} outdated records from pool" if pool.size != size

        file = IC::CONFIG[:pool_file]
        FileUtils.mkdir_p File.dirname(file)
        File.write file, JSON.pretty_generate(pool)
      end

      def save_used
        size = used.size

        # Удаляем устаревшие, если актуально
        taxon_uniq = IC::CONFIG[:taxon_uniq]
        if Integer === taxon_uniq
          dead_date = Date.today - taxon_uniq
          used.reject! { |_, value| value < dead_date }
          IC::logger.info "Removed #{size - used.size} outdated records from used" if used.size != size
        end

        file = IC::CONFIG[:used_file]
        FileUtils.mkdir_p File.dirname(file)
        File.write file, JSON.pretty_generate(used)
      end

      def save_sent
        size = sent.size
        
        # Удаляем устаревшие (-1 для надежности)
        dead_date = Date.today - IC::CONFIG[:pool_depth] - 1
        sent.reject! { |_, value| value['sent_at'] < dead_date }
        IC::logger.info "Removed #{size - sent.size} outdated records from sent" if sent.size != size

        file = IC::CONFIG[:sent_file]
        FileUtils.mkdir_p File.dirname(file)
        File.write file, JSON.pretty_generate(sent)
      end

    end

  end

end

module IC

  def select_uuid fresh
    INatChannel::Storage::select_uuid fresh
  end

  def save_data
    INatChannel::Storage::save
  end

  def confirm_sending! msg_id
    INatChannel::Storage::confirm! msg_id
  end

  def revert_sending!
    INatChannel::Storage::revert!
  end

  module_function :select_uuid, :save_data, :confirm_sending!, :revert_sending!

end
