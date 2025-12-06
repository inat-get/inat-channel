require 'time'
require 'json'
require 'fileutils'

module INatChannel

  DEFAULT_POOL_FILE = 'pool.json'
  DEFAULT_SENT_FILE = 'sent.json'

  # TODO: remove
  def pool_file
    CONFIG[:pool_file] || DEFAULT_POOL_FILE
  end

  # TODO: remove
  def sent_file
    CONFIG[:sent_file] || DEFAULT_SENT_FILE
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
    logger.info "Saved pool=#{pool.size}, sent=#{sent.size}"
  end

  def add_to_pool(new_uuids)
    new_pool = (pool + new_uuids).uniq - sent.keys
    @pool = new_pool
    logger.info "Added #{new_uuids.size} new UUIDs to pool (total: #{pool.size})"
  end

  def pop_random
    return nil if pool.empty?

    uuid = pool.sample
    pool.delete(uuid)

    sent[uuid] = nil
    logger.debug "Popped random UUID: #{uuid}"
    uuid
  end

  private

  def load_pool
    return [] unless File.exist?(pool_file)

    JSON.parse(File.read(pool_file), symbolize_names: true)
  rescue => e
    logger.warn "Failed to load pool from #{pool_file}: #{e.message}. Starting empty."
    []
  end

  def load_sent
    return {} unless File.exist?(sent_file)

    JSON.parse(File.read(sent_file), symbolize_names: true)
  rescue => e
    logger.warn "Failed to load sent from #{sent_file}: #{e.message}. Starting empty."
    {}
  end

  def save_pool
    FileUtils.mkdir_p(File.dirname(pool_file))
    pool.reject! { |k| sent.has_key?(k.intern) }
    File.write(pool_file, JSON.pretty_generate(pool))
  end

  def save_sent
    FileUtils.mkdir_p(File.dirname(sent_file))
    File.write(sent_file, JSON.pretty_generate(sent))
  end

  public

  LOCK_TTL = 1800  # 30 min

  def lock_file
    CONFIG[:lock_file] || File.join(File.dirname(pool_file), "bot.lock")
  end

  def acquire_lock!
    lock_path = lock_file
    FileUtils.mkdir_p(File.dirname(lock_path))
    
    if File.exist?(lock_path)
      lock_data = load_lock_data(lock_path)
      if stale_lock?(lock_data)
        logger.info "Removing stale lock #{lock_path}"
        File.delete(lock_path)
      else
        raise "Another instance is already running (PID: #{lock_data[:pid]})"
      end
    end

    create_lock_file(lock_path)
    logger.info "Lock acquired: #{lock_path}"
  end

  def release_lock
    lock_path = lock_file
    File.delete(lock_path) if File.exist?(lock_path)
    logger.info "Lock released: #{lock_path}"
  rescue
    logger.warn "Failed to release lock (ignored)"
  end

  private

  def load_lock_data(path)
    JSON.parse(File.read(path), symbolize_names: true)
  rescue
    {}
  end

  def stale_lock?(lock_data)
    return true unless lock_data[:started_at]
    
    started_at = Time.parse(lock_data[:started_at])
    (Time.now - started_at) > LOCK_TTL
  end

  def create_lock_file(path)
    lock_data = {
      pid: Process.pid,
      started_at: Time.now.utc.iso8601
    }
    File.write(path, JSON.pretty_generate(lock_data))
  end

end
