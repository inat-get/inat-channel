
module INatChannel

  def setup
    # TODO: parse command line options & load config (require 'optparse')
    #        command line params:
    #           -c OR --config    — select config file (default: './inat-channel.yaml')
    #           -l OR --log-level — log level (default: warnings)
    #                 --debug     — alias for `--log-level=debug`
    #           -h OR --help      — show usage info and exit

    # TODO: load telegram token and owner id from ENV
  end

  attr_reader :config, :telegram_token, :notify_telegram_id

end
