require 'set'

require_relative 'config'

module INatChannel

  module Message

    class << self

      def make_message observation
        [
          taxon_title(observation[:taxon]),
          observation_block(observation),
          "#{ICONS[:location]} #{geo_link(observation)}\n" + (place_block(observation[:place_ids]) || observation[:place_guess]),
          ancestors_block(observation)
        ].join("\n\n")
      end

      def list_photos observation
        return [] unless observation[:photos]
        observation[:photos].map { |ph| ph[:url].gsub("square", "large") }
      end

      private

      def taxon_title taxon
        icon = taxon_icon taxon
        link = "https://www.inaturalist.org/taxa/#{taxon[:id]}"

        common_name = taxon[:preferred_common_name]
        scientific_name = taxon[:name]

        title = if common_name
            "<b>#{common_name}</b> <i>(#{scientific_name})</i>"
          else
            "<b><i>#{scientific_name}</i></b>"
          end

        "#{icon} <a href='#{link}'>#{title}</a>"
      end

      def observation_block observation
        user = observation[:user]
        user_title = user[:name] || "<code>#{user[:login]}</code>"
        user_link = "https://www.inaturalist.org/people/#{user[:login]}"
        observation_part = "#{ICONS[:observation]} <a href='#{observation[:uri]}'><b>\##{observation[:id]}</b></a>"
        user_part = "#{ICONS[:user]} <a href='#{user_link}'>#{user_title}</a>"
        date_part = "#{ICONS[:calendar]} #{observation[:observed_on_string]}"
        description = observation[:description]&.gsub(/<[^>]*>/, "")
        description_part = if description && !description.empty?
            "\n#{ICONS[:description]} #{limit_text(description, 320)}"
          else
            ""
          end
        "#{observation_part}\n#{date_part}\n#{user_part}#{description_part}"
      end

      def limit_text text, limit
        return text if text.length <= limit
        truncated = text[0, limit]
        last_space = truncated.rindex /\s/
        last_sign = truncated.rindex /[,.;:!?]/
        if last_space
          if last_sign && last_sign + 1 > last_space
            return truncated[0, last_sign + 1]
          end
          return truncated[0, last_space]
        else
          if last_sign
            return truncated[0, last_sign + 1]
          end
          return truncated
        end
      end

      def place_block place_ids
        return nil unless CONFIG[:places]

        place_ids = Set[*place_ids]
        found = []
        CONFIG[:places].each do |_, list|
          list.each do |item|
            item_ids = Set[*item[:place_ids]]
            if place_ids.intersect?(item_ids)
              found << item
              break
            end
          end
        end

        if found.empty?
          nil
        else
          found.map { |i| "#{ICONS[:place]} <a href='#{i[:link]}'>#{i[:text]}</a>" }.join("\n")
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
          (ancestors.map { |a| name_to_hashtag(a[:name]) } + [name_to_hashtag(observation[:taxon][:name])]).join(" • ")
        else
          # TODO: load ancestors with new query...
          nil
        end
      end

      def name_to_hashtag name
        "\##{name.gsub(".", "").gsub("-", "").gsub(" ", "_")}"
      end

      def geo_link observation
        return nil unless observation[:geojson]&.[](:coordinates) && observation[:geojson][:type] == "Point"

        lon, lat = observation[:geojson][:coordinates]
        url = "https://maps.google.com/?q=#{lat},#{lon}"
        "<a href='#{url}'>#{lat.round(4)}°N, #{lon.round(4)}°E</a>"
      end

    end

  end

end
