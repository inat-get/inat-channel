require 'date'
require 'time'
require 'sanitize'

require_relative 'icons'

module INatChannel
  FORMATS = {
    date: '%Y.%m.%d',
    time: '%H:%M %Z',
    datetime: '%Y.%m.%d %H:%M %Z',
    location: :DMS,   # or :decimal
    zoom: 12,
    description_limit: 512
  }
end

class Date
  def icon
    INatChannel::Icons::ICONS[:calendar]
  end
  def to_s
    fmt = INatChannel::FORMATS[:date]
    if fmt
      self.strftime fmt
    else
      super
    end
  end
end

class Time
  def icon
    INatChannel::Icons::clock_icon self
  end
  def to_s
    fmt = INatChannel::FORMATS[:time]
    if fmt
      self.strftime fmt
    else
      super
    end
  end
end

class DateTime
  def icon
    INatChannel::Icons::ICONS[:calendar]
  end
  def to_s
    fmt = INatChannel::FORMATS[:datetime]
    if fmt
      self.strftime fmt
    else
      super
    end
  end
end

class String
  def to_tag
    "\##{self.gsub(/\s+/, '_').gsub(/-/, '_').gsub(/[^a-zA-Zа-яА-ЯёЁ_]/, '')}"
  end
  def limit len
    return self if length <= len

    short = self[0, len]
    last_space = short.rindex(/\s/)
    last_sign = short.rindex(/[,.;:!?]/)
    if last_space
      if last_sign && last_sign + 1 > last_space
        return short[0, last_sign + 1] + '...'
      end
      return short[0, last_space] + '...'
    else
      if last_sign
        return short[0, last_sign + 1] + '...'
      end
      return short + '...'
    end
  end
end

class Array 
  def to_tags
    self.map do |item| 
      if item.respond_to?(:to_tag)
        item.to_tag 
      else
        item&.to_s.to_tag
      end
    end.compact
  end
end

Observation = Struct::new :taxon, :id, :uuid, :url, :user, :datetime, :places, :place_guess, :description, :location, keyword_init: true do
  def icon
    INatChannel::Icons::ICONS[:observation]
  end
  def date
    datetime.to_date
  end
  def time
    datetime.to_time
  end
end

Taxon = Struct::new :scientific_name, :common_name, :id, :ancestors, keyword_init: true do
  def icon
    INatChannel::Icons::ancestors_icon ancestors.map(&:id)
  end
  def title
    if common_name && !common_name.empty?
      "<b>#{common_name}</b> <i>(#{scientific_name})</i>"
    else
      "<b><i>#{scientific_name}</i></b>"
    end
  end
  def url
    "https://www.inaturalist.org/taxa/#{id}"
  end
  def to_tags
    ancestors.to_tags
  end
end

Ancestor = Struct::new :scientific_name, :id, keyword_init: true do
  def to_tag
    scientific_name.to_tag
  end
end

Place = Struct::new :ids, :text, :link, :tag, keyword_init: true do
  def icon
    INatChannel::Icons::ICONS[:place]
  end
  def to_tag
    tag&.to_tag
  end
  def title
    text
  end
  def url
    link
  end
end

User = Struct::new :id, :login, :name, keyword_init: true do
  def icon
    INatChannel::Icons::ICONS[:user]
  end
  def title
    if name && !name.empty?
      name
    else
      "@#{login}"
    end
  end
  def url 
    "https://www.inaturalist.org/people/#{id}"
  end
end

SANITIZE_HTML_CONFIG = {
  elements: [ 'b', 'strong', 'i', 'em', 'u', 's', 'strike', 'del', 'a', 'code', 'pre', 'tg-spoiler', 'blockquote' ],
  attributes: { 'a' => [ 'href' ] },
  protocols: { 'a' => { 'href' => [ 'http', 'https', 'mailto', 'tg' ] } },
  remove_contents: [ 'script', 'style' ]
}

SANITIZE_TEXT_CONFIG = {
  elements: [],
  remove_contents: [ 'script', 'style' ]
}

Description = Struct::new :value, keyword_init: true do
  def icon
    INatChannel::Icons::ICONS[:description]
  end
  def text
    Sanitize.fragment(value, SANITIZE_TEXT_CONFIG).limit(FORMATS[:description_limit])
  end
  def html
    sanitized = Sanitize.fragment value, SANITIZE_HTML_CONFIG
    if sanitized.length > FORMATS[:description_limit]
      # В отличие от простого текста, обрезка HTML требует куда более изощренной логики, что неоправданно
      text
    else
      sanitized
    end
  end
end

Location = Struct::new :lat, :lng, keyword_init: true do
  def icon
    INatChannel::Icons::ICONS[:location]
  end
  def title
    lat_dir = lat >= 0 ? 'N' : 'S'
    lng_dir = lng >= 0 ? 'E' : 'W'
    lat_abs = lat.abs
    lng_abs = lng.abs
    if FORMATS[:location] == :DMS
      lat_d = lat_abs.floor
      lat_m = ((lat_abs - lat_d) * 60).floor
      lat_s = ((lat_abs - lat_d - lat_m / 60.0) * 3600).round
      lng_d = lng_abs.floor
      lng_m = ((lng_abs - lng_d) * 60).floor
      lng_s = ((lng_abs - lng_d - lng_m / 60.0) * 3600).round
      "%d°%02d'%02d\"%s %d°%02d'%02d\"%s" % [ lat_d, lat_m, lat_s, lat_dir, lng_d, lng_m, lng_s, lng_dir ]
    else
      "%.4f°%s, %.4f°%s" % [ lat_abs, lat_dir, lng_abs, lng_dir ]
    end
  end
  def google
    # "https://www.google.com/maps/search/?api=1&query=#{lat},#{lng}&z=#{FORMATS[:zoom]}&ll=#{lat},#{lng}"
    "https://www.google.com/maps/place/#{lat},#{lng}/@#{lat},#{lng},#{FORMATS[:zoom]}z/"
  end
  def yandex
    "https://yandex.ru/maps/?ll=#{lng},#{lat}&z=#{FORMATS[:zoom]}&pt=#{lng},#{lat},pm2rdm1"
  end
  def osm
     "https://www.openstreetmap.org/?mlat=#{lat}&mlon=#{lng}#map=#{FORMATS[:zoom]}/#{lat}/#{lng}"
  end
  def url
    osm
  end
end

