
module INatChannel

  TAXA_ICONS = {
    48460 => '🧬',
    47126 => '🌿'
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

  def taxon_icon taxon
    taxon[:ancestor_ids].reverse_each do |ancestor_id|
      return TAXA_ICONS[ancestor_id] if TAXA_ICONS[ancestor_id] 
    end
    return ICONS[:default_taxon]
  end

end
