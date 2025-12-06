require 'date'
require 'json'
require 'faraday'
require 'faraday/retry'

require_relative 'config'
require_relative 'logger'

module INatChannel

  module API

    class << self

      PER_PAGE = 200
      PAGE_DELAY = 1.0
      API_ENDPOINT = 'https://api.inaturalist.org/v2/observations'
      LIST_FIELDS = 'uuid'
      SINGLE_FIELDS = '(id:!t,uuid:!t,uri:!t,geojson:(all:!t),user:(login:!t,name:!t),taxon:(ancestor_ids:!t,preferred_common_name:!t,name:!t),' +
                      'place_ids:!t,place_guess:!t,observed_on_string:!t,description:!t,photos:(url:!t),identifications:(taxon:(ancestors:(name:!t))))'

      private_constant :PER_PAGE, :PAGE_DELAY, :API_ENDPOINT, :LIST_FIELDS, :SINGLE_FIELDS

      def load_news 
        result = []
        page = 1

        loop do 
          INatChannel::LOGGER.debug "Fetch page #{page} with per_page=#{PER_PAGE}"

          response = faraday.get API_ENDPOINT do |req|
            req.params['page'] = page
            req.params['per_page'] = PER_PAGE
            req.params['fields'] = LIST_FIELDS
            req.params.merge! INatChannel::CONFIG[:base_query]
            req.params['created_d1'] = (Date.today - INatChannel::CONFIG[:days_back]).to_s
          end

          unless response.success?
            INatChannel::Telegram::notify_admin "Failed to fetch observations page #{page}: HTTP #{response.status}"
            INatChannel::LOGGER.error "HTTP #{response.status} on page #{page}"
            break
          end

          data = JSON.parse response.body, symbolize_names: true
          uuids = data[:results].map { |o| o[:uuid] }
          result += uuids

          total = data[:total_results] || 0
          INatChannel::LOGGER.debug "Page #{page}: fetched #{uuids.size} UUIDs, total expected #{total}"

          break if uuids.empty? || result.size >= total
          page += 1
          sleep PAGE_DELAY
        end

        INatChannel::LOGGER.debug "Loaded total #{result.uniq.size} unique UUIDs"
        result.uniq
      rescue => e
        INatChannel::Telegram::notify_admin "Exception while loading news: #{e.message}"
        INatChannel::LOGGER.error e.full_message
        []
      end

      def load_observation uuid
        response = faraday.get API_ENDPOINT do |req|
          req.params['uuid'] = uuid
          req.params['locale'] = INatChannel::CONFIG[:base_query][:locale] if INatChannel::CONFIG[:base_query][:locale]
          req.params['fields'] = SINGLE_FIELDS
        end

        if response.success?
          data = JSON.parse response.body, symbolize_names: true
          obs = data[:results]&.first
          INatChannel::LOGGER.debug "Loaded observation: #{uuid}"
          obs
        else
          INatChannel::LOGGER.error "Error loading observation #{uuid}: HTTP #{response.status}"
          INatChannel::Telegram::notify_admin "Error loading observation #{uuid}: HTTP #{response.status}"
          nil
        end
      rescue => e
        INatChannel::Telegram::notify_admin "Exception while loading observation #{uuid}: #{e.message}"
        INatChannel::LOGGER.error e.full_message
        nil
      end

      private

      def faraday
        @faraday ||= Faraday::new do |f|
          f.request :retry, max: INatChannel::CONFIG[:retries], interval: 2.0, interval_randomness: 0.5,
                            exceptions: [ Faraday::TimeoutError, Faraday::ConnectionFailed, Faraday::SSLError, Faraday::ClientError ]
          f.request :url_encoded

          if INatChannel::LOGGER.level == ::Logger::DEBUG
            f.response :logger, INatChannel::LOGGER, bodies: true, headers: true 
          end

          f.adapter Faraday::default_adapter
        end
      end

    end

  end

end
