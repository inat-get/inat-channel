require 'set'
require 'sanitize'

require_relative 'config'
require_relative 'icons'
require_relative 'template'

module INatChannel

  module Message

    class << self

      def make_message observation
        template = if IC::CONFIG[:template]
          IC::load_template IC::CONFIG[:template]
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

  def make_message observation
    INatChannel::Message::make_message observation
  end

  def list_photos observation
    INatChannel::Message::list_photos observation
  end

  module_function :make_message, :list_photos

end

