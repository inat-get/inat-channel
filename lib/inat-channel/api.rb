require 'faraday'
require 'json'

module INatChannel

  PER_PAGE = 200
  DELAY = 1.0

  def load_news
  
    uuids = []
    page = 1

    loop do
      logger.debug "Fetch page #{page} with per_page=#{PER_PAGE}"
      response = faraday.get('https://api.inaturalist.org/v2/observations') do |req|
        req.params['page'] = page
        req.params['per_page'] = PER_PAGE
        req.params['fields'] = 'uuid'         
        req.params.merge!(parse_base_query)   
      end

      unless response.success?
        notify_admin "Failed to fetch observations page #{page}: HTTP #{response.status}"
        logger.error "HTTP #{response.status} on page #{page}"
        break
      end

      data = JSON.parse response.body, symbolize_names: true
      page_uuids = data[:results].map { |obs| obs[:uuid] }
      uuids.concat page_uuids

      total_results = data[:total_results] || 0
      logger.info "Page #{page}: fetched #{page_uuids.size} UUIDs, total expected #{total_results}"

      break if page_uuids.empty? || (uuids.size >= total_results)
      page += 1

      sleep DELAY
    end

    logger.info "Loaded total #{uuids.uniq.size} unique UUIDs"
    uuids.uniq
  rescue => e
    notify_admin "Exception while loading news: #{e.message}"
    logger.error e.full_message
    []
  end

  def load_observation(uuid)
    url = "https://api.inaturalist.org/v2/observations/#{uuid}"
    response = faraday.get(url)

    if response.success?
      data = JSON.parse response.body, symbolize_names: true
      obs = data[:results]&.first
      logger.debug "Loaded observation #{uuid}"
      obs
    else
      notify_admin("Failed to load observation #{uuid}: HTTP #{response.status}")
      logger.error "Error loading observation #{uuid}: HTTP #{response.status}"
      nil
    end
  rescue => e
    notify_admin("Exception loading observation #{uuid}: #{e.message}")
    logger.error e.full_message
    nil
  end

  private

  def faraday
    @faraday ||= Faraday.new do |f|
      f.request :retry, max: (config[:retries] || 3), interval: 1.0, exceptions: [Faraday::TimeoutError]
      f.adapter Faraday.default_adapter
    end
  end

  def parse_base_query
    return {} unless config[:base_query]
    Hash[config[:base_query].split('&').map { |param| param.split('=', 2) }]
  end

end
