require 'set'
require 'sanitize'

require_relative 'config'
require_relative 'icons'
require_relative 'template'

module INatChannel

  module Message

    class << self

      def make_message observation
        template = if INatChannel::CONFIG[:template]
          INatChannel::Template::load INatChannel::CONFIG[:template]
        else
          INatChannel::Template::default
        end
        template.process observation
      end

      def list_photos observation
        return [] unless observation[:photos]
        observation[:photos].map { |ph| ph[:url].gsub("square", "large") }
      end

    end

  end

end
