require 'set'
require 'sanitize'

require_relative 'facade'
require_relative 'config'
require_relative 'icons'
require_relative 'template'

module INatChannel

  module Message

    class << self

      def make_message observation
        template = if IC::CONFIG.dig(:tg_bot, :template)
          IC::load_template IC::CONFIG.dig(:tg_bot, :template)
        else
          IC::default_template
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

module IC

  self >> INatChannel::Message

  shadow_encapsulate INatChannel::Message, :make_message, :list_photos

end

