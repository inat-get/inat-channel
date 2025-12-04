
require_relative 'config'

module INatChannel

  def make_message observation
    [
      taxon_title(observation[:taxon]),
      observation_block(observation),
      place_block(observation[:place_ids]) || observation[:place_guess],
      ancestors_block(taxon)
    ].join('<br><br>')
  end

  def list_photos observation
    observation[:photos].map ( |ph| ph[:url].gsub('square', 'original') )
  end

  private

  def taxon_title taxon

    icon = taxon_icon taxon
    link = "https://www.inaturalist.org/taxa/#{ taxon[:id] }"

    common_name = taxon[:preferred_common_name]
    scientific_name = taxon[:name]

    title = if common_name
      "<b>#{ common_name }</b> <i>(#{ scientific_name })</i>"
    else
      "<b><i>#{ scientific_name }</i></b>"
    end

    "#{ icon } <a href='#{ link }'>#{ title }</a>"
  end

  def observation_block observation
    user = observation[:user]
    user_title = user[:name] || "<code>#{ user[:login] }</code>"
    user_link = "https://www.inaturalist.org/people/#{ user[:id] }"
    observation_part = "#{ ICONS[:observation] } <a href='#{ observation[:uri] }'>\##{ observation[:id] }</a>"
    user_part = "#{ ICONS[:user] } <a href='#{ user_link }'>#{ user_title }</a>"
    date_part = "#{ ICONS[:calendar] } #{ observation[:observed_on_string] }"
    description = observation[:description]
    description_part = if description && !description.empty?
      "<br>#{ ICONS[:description] } #{ description }"
    else
      ''
    end
    "#{ observation_part } — #{ user_part } @ #{ date_part } #{ description_part }"
  end

  def place_block place_ids
    found = []
    config[:places].each do |_, list|
      list.each do |item|
        item_ids = item[:place_ids]
        if place_ids.intersect?(item_ids)
          found << item
          break
        end
      end
    end

    if found.empty?
      nil
    else
      found.map { |i| "#{ ICONS[:place] } <a href='#{ i[:link] }'>#{ i[:title] }</a>" }.join('<br>')
    end
  end

  def ancestors_block observation
    taxon_id = observation[:taxon][:id]
    ancestors = nil
    observation[:identifications].each do |ident|
      it = ident[:taxon]
      if it[:id] == taxon_id
        ancestors = it[:ancestors]
        break
      end
    end

    if ancestors
      ancestors.map { |a| name_to_hashtag(a[:name]) }.join(' • ')
    else
      # TODO: load ancestors with new query...
      nil
    end
  end

  def name_to_hashtag name
    "\##{ name.gsub('.', '').gsub('-', '').gsub(' ', '_') }"
  end

end
