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
      LIST_FIELDS = '(uuid:!t,created_at:!t,faves_count:!t,taxon:(id:!t))'
      SINGLE_FIELDS = '(id:!t,uuid:!t,uri:!t,geojson:(all:!t),user:(login:!t,name:!t),taxon:(ancestor_ids:!t,preferred_common_name:!t,name:!t),' +
                      'place_ids:!t,place_guess:!t,observed_on_string:!t,description:!t,photos:(url:!t),time_observed_at:!t,' +
                      'identifications:(taxon:(ancestors:(name:!t))))'

      private_constant :PER_PAGE, :PAGE_DELAY, :API_ENDPOINT, :LIST_FIELDS, :SINGLE_FIELDS

      def load_news 
        load_list(**IC::CONFIG[:base_query], created_d1: (Date.today - IC::CONFIG.dig(:days_back, :fresh)).to_s)
      end
      
      def load_list **query
        result = []
        page = 1
        
        loop do 
          IC::logger.debug "Fetch page #{page} with per_page=#{PER_PAGE}"

          response = faraday.get API_ENDPOINT do |req|
            req.params[:page] = page
            req.params[:per_page] = PER_PAGE
            req.params[:fields] = LIST_FIELDS
            req.params.merge! query
          end

          unless response.success?
            IC::logger.error "❌ Failed to fetch observations page #{page}: HTTP #{response.status}"
            IC::notify_admin "❌ Failed to fetch observations page #{page}: HTTP #{response.status}"
            break
          end

          data = JSON.parse response.body, symbolize_names: true
          result += data[:results]

          total = data[:total_results] || 0
          IC::logger.debug "Page #{page}: fetched #{data.size} records, total expected #{total}"
          break if data.empty? || result.size >= total
          page += 1
          sleep PAGE_DELAY
        end

        IC::logger.debug "Loaded total #{result.size} records"
        result
      rescue => e
        IC::logger.error "❌ Exception while loading news: #{e.full_message}"
        IC::notify_admin "❌ Exception while loading news: #{e.message}"
      end

      def load_observation uuid
        response = faraday.get API_ENDPOINT do |req|
          req.params['uuid'] = uuid
          req.params['locale'] = IC::CONFIG[:base_query][:locale] if IC::CONFIG[:base_query][:locale]
          req.params['fields'] = SINGLE_FIELDS
        end

        if response.success?
          data = JSON.parse response.body, symbolize_names: true
          obs = data[:results]&.first
          IC::logger.debug "Loaded observation: #{uuid}"
          obs
        else
          IC::logger.error "Error loading observation #{uuid}: HTTP #{response.status}"
          IC::notify_admin "Error loading observation #{uuid}: HTTP #{response.status}"
          nil
        end
      rescue => e
        IC::notify_admin "Exception while loading observation #{uuid}: #{e.message}"
        IC::logger.error e.full_message
        nil
      end

      private

      def faraday
        @faraday ||= Faraday::new do |f|
          f.request :retry, 
                    max: IC::CONFIG.dig(:api, :retries), 
                    interval: IC::CONFIG.dig(:api, :interval), 
                    interval_randomness: IC::CONFIG.dig(:api, :randomness),
                    exceptions: [ Faraday::TimeoutError, Faraday::ConnectionFailed, Faraday::SSLError, Faraday::ClientError ]
          f.request :url_encoded

          if IC::logger.level == ::Logger::DEBUG
            f.response :logger, IC::logger, bodies: true, headers: true 
          end

          f.adapter Faraday::default_adapter
        end
      end

    end

  end

end

module IC

  def load_news
    INatChannel::API::load_news
  end

  def load_observation uuid
    INatChannel::API::load_observation uuid
  end

  def load_list **query
    INatChannel::API::load_list(**query)
  end

  module_function :load_news, :load_observation

end

