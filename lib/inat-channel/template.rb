require 'yaml'
require 'erb'

require_relative 'data_types'
require_relative 'data_convert'

module INatChannel

  class Template

    attr_reader :template, :data

    def initialize template, data
      @template = template
      @data = data
      @renderer = ERB::new @template, trim_mode: '-'
      IC::TAXA_ICONS.merge! data[:taxa_icons] if data[:taxa_icons]
      IC::ICONS.merge! data[:icons] if data[:icons]
      IC::FORMATS.merge! data[:formats] if data[:formats]
    end

    def process observation_source
      observation = IC::convert_observation observation_source
      vars = {
        observation: observation,
        datetime: observation.datetime,
        location: observation.location,
        places: observation.places,
        taxon: observation.taxon,
        user: observation.user,
        date: observation.date,
        time: observation.time,
        icons: IC::ICONS,
        taxa_icons: IC::TAXA_ICONS
      }
      @renderer.result_with_hash vars
    end

    class << self

      def load path
        content = File.read path
        if content.lines(chomp: true).first == '---'
          docs = content.split(/^---\n/m, 3)
          data = if docs[0].strip.empty? && docs[1]
            YAML.safe_load docs[1], symbolize_names: true
          else
            YAML.safe_load docs[0], symbolize_names: true
          end || {}
          template = docs[2] || docs[1] || content
        else
          data = {}
          template = content
        end
        new(template, data)
      end

      DEFAULT_TEMPLATE = <<~ERB
        <%= taxon.icon %> <a href="<%= taxon.url %>"><%= taxon.title %></a>

        <%= observation.icon %> <a href="<%= observation.url %>">#<%= observation.id %></a>
        <%= datetime.icon %> <%= datetime %>
        <%= user.icon %> <a href="<%= user.url %>"><%= user.title %></a>
        <% if observation.description -%>
        <blockquote><%= observation.description.text %></blockquote>
        <% end -%>

        <%= location.icon %> <%= location.title %> • <a href="<%= location.google %>">G</a> <a href="<%= location.osm %>">OSM</a>
        <% if places && places.size > 0 -%>
        <%   places.each do |place| -%>
        <%= place.icon %> <a href="<%= place.link %>"><%= place.text %></a> <%= '• #' + place.tag if place.tag %>
        <%   end -%>
        <% else -%>
        <%= icons[:place] %> <%= observation.place_guess %>
        <% end -%>

        <%= taxon.to_tags&.join(' • ') %>
      ERB

      def default
        @default ||= new(DEFAULT_TEMPLATE, {}).freeze
      end

      private :new

    end

  end

end

module IC

  def load_template path
    INatChannel::Template::load path
  end

  def default_template
    INatChannel::Template::default
  end

end
