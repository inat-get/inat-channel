require 'telegram/bot'

module INatChannel

  def bot
    @bot ||= ::Telegram::Bot::Client.new(telegram_token)
  end

  def send_observation(observation)
    photos = list_photos(observation)
    message = make_message(observation)
    
    if photos.any?
      media = photos[0..9].map { |url| { type: 'photo', media: url } }
      media.last[:caption] = message
      media.last[:parse_mode] = 'HTML'
      response = bot.api.send_media_group(chat_id: config[:chat_id], media: media)
      main_msg_id = response.results.last.message_id
    else
      response = bot.api.send_message(chat_id: config[:chat_id], text: message, parse_mode: 'HTML')
      main_msg_id = response.message_id
    end
    
    if observation[:geojson]&.[](:coordinates) && observation[:geojson][:type] == 'Point'
      lon, lat = observation[:geojson][:coordinates]
      bot.api.send_location(
        chat_id: config[:chat_id],
        latitude: lat,
        longitude: lon,
        reply_to_message_id: main_msg_id 
      )
      logger.debug "Sent geo ↳ #{lat}, #{lon}"
    end
    
    sent[observation[:uuid]] = { msg_id: main_msg_id, sent_at: Time.now.to_s }
    logger.info "Sent #{observation[:id]} (#{photos.size} photos) + geo"
  rescue => e
    notify_admin("Send failed: #{e.message}")
    logger.error e.full_message
  end

  def notify_admin(text)
    bot.api.send_message(chat_id: notify_telegram_id, text: "❌ iNatChannel: #{text}")
  rescue => e
    logger.error "Admin notify failed: #{e.message}"
  end

end
