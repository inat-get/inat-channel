require 'json'
require 'fileutils'

module INatChannel

  DEFAULT_POOL_FILE = 'pool.json'
  DEFAULT_SENT_FILE = 'sent.json'

  def pool_file
    config[:pool_file] || DEFAULT_POOL_FILE
  end

  def sent_file
    config[:sent_file] || DEFAULT_SENT_FILE
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
    File.write(pool_file, JSON.pretty_generate(pool))
  end

  def save_sent
    FileUtils.mkdir_p(File.dirname(sent_file))
    File.write(sent_file, JSON.pretty_generate(sent))
  end

end
