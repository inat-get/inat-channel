module INatChannel
  module Icons
    TAXA_ICONS = {
      48460 => "🧬",
      47126 => "🌿",
      47170 => "🍄",
      47686 => "🦠",
      151817 => "🦠",
      67333 => "🦠",
      1 => "🐾",
      136329 => "🌲",
      47124 => "🌸",
      47163 => "🍃",
      47178 => "🐟",
      196614 => "🦈",
      47187 => "🦀",
      47158 => "🪲",
      47119 => "🕷️",
      71261 => "🦅",
      18874 => "🦜",
      48222 => "🌊",
      47115 => "🐚",
      3 => "🐦",
      40151 => "🦌",
      26036 => "🐍",
      20978 => "🐸",

    # TODO: add ALL taxa with iNat icons and some other large group
    }

    ICONS = {
      :user => "👤",
      :place => "🗺️",
      :calendar => "📅",
      :location => "📍",
      :observation => "📷",
      :description => "📝",
      :default_taxon => "🧬",
    # TODO: add other icons like calendar, place, etc.
    }

    class << self
      def taxon_icon taxon
        ancestors_icon taxon[:ancestor_ids]
      end

      def ancestors_icon ancestor_ids 
        ancestor_ids.reverse_each do |ancestor_id|
          return TAXA_ICONS[ancestor_id] if TAXA_ICONS[ancestor_id]
        end
        return ICONS[:default_taxon]
      end

      def clock_icon time
        hour = time.hour % 12
        minute = time.min

        if minute <= 20
          # ≤20 мин - текущий час
          case hour
          when 0, 12 then "🕛"
          when 1 then "🕐"
          when 2 then "🕑"
          when 3 then "🕒"
          when 4 then "🕓"
          when 5 then "🕔"
          when 6 then "🕕"
          when 7 then "🕖"
          when 8 then "🕗"
          when 9 then "🕘"
          when 10 then "🕙"
          when 11 then "🕚"
          end
        elsif minute < 40
          # 21-39 мин - полчаса текущего часа
          case hour
          when 0, 12 then "🕧"
          when 1 then "🕜"
          when 2 then "🕝"
          when 3 then "🕞"
          when 4 then "🕟"
          when 5 then "🕠"
          when 6 then "🕡"
          when 7 then "🕢"
          when 8 then "🕣"
          when 9 then "🕤"
          when 10 then "🕥"
          when 11 then "🕦"
          end
        else
          # ≥40 мин - следующий час
          next_hour = (hour + 1) % 12
          case next_hour
          when 0, 12 then "🕛"
          when 1 then "🕐"
          when 2 then "🕑"
          when 3 then "🕒"
          when 4 then "🕓"
          when 5 then "🕔"
          when 6 then "🕕"
          when 7 then "🕖"
          when 8 then "🕗"
          when 9 then "🕘"
          when 10 then "🕙"
          when 11 then "🕚"
          end
        end
      end

    end

  end

end
