require_relative 'config'
require_relative 'logger'
require_relative 'message'

module INatChannel

  module Telegram

    class << self

      TELEGRAM_API = 'https://api.telegram.org/bot'

      def send_observation observation
        photos = INatChannel::Message::list_photos observation
        message = INatChannel::Message::make_message observation

        unless photos.empty?
          msg_id = send_media_group INatChannel::CONFIG[:chat_id], photos[0..9], message
        else
          msg_id = send_message INatChannel::CONFIG[:chat_id], message
        end

        INatChannel::Data::sent[observation[:uuid]] = { msg_id: msg_id, sent_at: Time.now.to_s }
        INatChannel::LOGGER.info "Posted #{observation[:id]} (#{photos.size} photos)"
        msg_id
      end

      def notify_admin(text)
        send_message(notify_telegram_id, "❌ iNatChannel: #{text}")
      rescue
        INatChannel::LOGGER.error "Admin notify failed"
      end

      private

      def token 
        @token ||= INatChannel::CONFIG[:telegram_bot_token]
      end

      def send_message chat_id, text
        response = faraday.post "#{TELEGRAM_API}#{token}/sendMessage" do |req|
          req.params['chat_id'] = chat_id
          req.headers['Content-Type'] = 'application/json'
          req.body = { text: text, parse_mode: 'HTML' }.to_json
        end
      
        data = JSON.parse response.body, symbolize_names: true
        raise "Telegram error: #{data[:description]} (#{data[:error_code]})" unless data[:ok]
        data[:result][:message_id]
      end

      def send_media_group chat_id, photo_urls, caption
        media = photo_urls.map.with_index do |url, i|
          if i == photo_urls.size - 1
            { type: 'photo', media: url, caption: caption, parse_mode: 'HTML' }
          else
            { type: 'photo', media: url }
          end
        end.to_json

        response = faraday.post "#{TELEGRAM_API}#{token}/sendMediaGroup" do |req|
          req.params['chat_id'] = chat_id
          req.headers['Content-Type'] = 'application/json'
          req.body = { media: media }.to_json
        end

        data = JSON.parse response.body, symbolize_names: true
        raise "Telegram error: #{data[:description]} (#{data[:error_code]})" unless data[:ok]
        data[:result].last[:message_id]
      end

      def faraday
        @faraday ||= Faraday.new do |f|
          f.request :retry, max: INatChannel::CONFIG[:retries], interval: 2.0, interval_randomness: 0.5,  
                    exceptions: [ Faraday::TimeoutError, Faraday::ConnectionFailed, Faraday::SSLError, Faraday::ClientError ]
    
          if INatChannel::LOGGER.level == ::Logger::DEBUG
            f.response :logger, INatChannel::LOGGER, bodies: true, headers: true 
          end
    
          f.adapter Faraday.default_adapter
        end
      end

    end

  end

end
