
module INatChannel

  module Icons

    TAXA_ICONS = {
      48460  => '🧬',
      47126  => '🌿',
      47170  => '🍄',
      47686  => '🦠',
      151817 => '🦠',
      67333  => '🦠',
      1      => '🐾',
      136329 => '🌲',
      47124  => '🌸',
      47163  => '🍃',
      47178  => '🐟',
      196614 => '🦈',
      47187  => '🦀',
      47158  => '🪲',
      47119  => '🕷️',
      71261  => '🦅',
      18874  => '🦜',
      48222  => '🌊',
      47115  => '🐚',
      3      => '🐦',
      40151  => '🦌',
      26036  => '🐍',
      20978  => '🐸'

      # TODO: add ALL taxa with iNat icons and some other large group
    }.freeze

    ICONS = {
      :user => '👤',
      :place => '🗺️',
      :calendar => '📅',
      :location => '📍',
      :observation => '📷',
      :description => '📝',
      :default_taxon => '🧬'
      # TODO: add other icons like calendar, place, etc.
    }.freeze

    class << self

      def taxon_icon taxon
        taxon[:ancestor_ids].reverse_each do |ancestor_id|
          return TAXA_ICONS[ancestor_id] if TAXA_ICONS[ancestor_id] 
        end
        return ICONS[:default_taxon]
      end

    end

  end

end
