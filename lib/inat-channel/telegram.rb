
module INatChannel

  TELEGRAM_API = 'https://api.telegram.org/bot'.freeze

  def send_observation(observation)
    photos = list_photos(observation)
    message = make_message(observation)
    
    if photos.any?
      main_msg_id = send_media_group(config[:chat_id], photos[0..9], message)
    else
      main_msg_id = send_message(config[:chat_id], message)
    end
    
    sent[observation[:uuid]] = { msg_id: main_msg_id, sent_at: Time.now.to_s }
    logger.info "✅ Posted #{observation[:id]} (#{photos.size} photos)"
  end

  private

  def send_message(chat_id, text)
    response = telegram_faraday.post("#{TELEGRAM_API}#{telegram_token}/sendMessage") do |req|
      req.params['chat_id'] = chat_id
      req.params['text'] = text
      req.params['parse_mode'] = 'HTML'
    end
  
    data = response.body  # уже символизированный хэш!
    unless data[:ok]
      raise "Telegram error: #{data[:description]} (#{data[:error_code]})"
    end
  
    data[:result][:message_id]
  end

  def send_media_group(chat_id, photo_urls, caption)
    media = photo_urls.map.with_index do |url, i|
      if i == photo_urls.size - 1
        { type: 'photo', media: url, caption: caption, parse_mode: 'HTML' }
      else
        { type: 'photo', media: url }
      end
    end.to_json

    response = telegram_faraday.post("#{TELEGRAM_API}#{telegram_token}/sendMediaGroup") do |req|
      req.params['chat_id'] = chat_id
      req.headers['Content-Type'] = 'application/json'
      req.body = { media: media }.to_json  # media в теле!
    end
  
    data = JSON.parse response.body, symbolize_names: true
    unless data[:ok]
      raise "Telegram error: #{data[:description]} (#{data[:error_code]})"
    end
  
    data[:result].last[:message_id]
  end

  # def telegram_token
  #   @telegram_token
  # end

  def notify_admin(text)
    send_message(notify_telegram_id, "❌ iNatChannel: #{text}")
  rescue
    logger.error "Admin notify failed"
  end

end
