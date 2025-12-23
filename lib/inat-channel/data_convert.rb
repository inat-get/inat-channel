require 'date'
require 'time'
require 'set'

require_relative 'facade'
require_relative 'data_types'

module INatChannel

  module DataConvert

    class << self

      def convert_observation observation_source
        begin
          id = observation_source[:id]
          url = observation_source[:uri]
          uuid = observation_source[:uuid]
          user = convert_user observation_source[:user]
          taxon = convert_taxon observation_source[:taxon], observation_source[:identifications]
          places = convert_places observation_source[:place_ids]
          datetime = DateTime.parse(observation_source[:time_observed_at] || observation_source[:observed_on_string])
          location = convert_location observation_source[:geojson]
          description = convert_description observation_source[:description]
          place_guess = observation_source[:place_guess]
        rescue => e
          IC::logger.error e.full_message
          IC::logger.info JSON.pretty_generate(observation_source)
          raise e
        end
        Observation::new id: id, url: url, uuid: uuid, user: user, taxon: taxon, places: places, datetime: datetime, location: location, description: description, place_guess: place_guess
      end

      private

      def convert_location location_source
        return nil unless location_source
        lat = location_source.dig :coordinates, 1
        lng = location_source.dig :coordinates, 0
        return nil unless lat && lng
        Location::new lat: lat, lng: lng
      end

      def convert_description description_source
        return nil if description_source.nil? || description_source.empty?
        Description::new value: description_source
      end

      def convert_user user_source
        User::new id: user_source[:id], login: user_source[:login], name: user_source[:name]
      end

      def convert_taxon taxon_source, identifications
        id = taxon_source[:id]
        scientific_name = taxon_source[:name]
        common_name = taxon_source[:preferred_common_name]
        source_ancestors = nil
        identifications.each do |ident|
          it = ident[:taxon]
          if it[:id] == id
            source_ancestors = it[:ancestors]
            break
          end
        end
        ancestors = if source_ancestors
          source_ancestors.map do |anc|
            Ancestor::new id: anc[:id], scientific_name: anc[:name]
          end
        else
          taxon_source[:ancestor_ids].map do |aid|
            Ancestor::new id: aid
          end
          # TODO: load names from API by ancestor_ids
        end
        ancestors << Ancestor::new(id: taxon_source[:id], scientific_name: taxon_source[:name])
        Taxon::new id: id, scientific_name: scientific_name, common_name: common_name, ancestors: ancestors
      end

      def convert_places place_ids
        places_config = IC::CONFIG[:places]
        return nil unless places_config
        result = []
        places_config.each do |_, items|
          items.each do |item|
            ids = Set[*item[:place_ids]]
            if ids.intersect?(place_ids)
              result << Place::new(text: item[:text], link: item[:link], tag: item[:tag])
              break
            end
          end
        end
        result
      end

    end

  end

end

module IC 

  self >> INatChannel::DataConvert

  shadow_encapsulate INatChannel::DataConvert, :convert_observation

end
