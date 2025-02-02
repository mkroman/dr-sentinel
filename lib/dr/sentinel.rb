# frozen_string_literal: true

require 'rss'
require 'httpx'
require 'sequel'
require 'nokogiri'
require 'logging'
require 'zstd-ruby'

# Set up logging
Logging.color_scheme(
  'meta',
  levels: {
    debug: :white,
    info: :cyan,
    warn: :yellow,
    error: :red,
    fatal: :orange
  },
  date: :white,
  logger: %i[white bold],
  message: :white
)

Logging.appenders.stdout(
  'stdout',
  layout: Logging.layouts.pattern(
    pattern: '%d %-24.24c %-5l %m\n',
    date_pattern: '%Y-%m-%d %H:%M:%S',
    color_scheme: 'meta'
  )
)

Logging.logger.root.appenders = Logging.appenders.stdout
Logging.logger.root.level = :debug

require_relative './sentinel/version'
require_relative './sentinel/server'

module DR
  module Sentinel
    DEFAULT_DATABASE_URL = 'sqlite://db/database.db'
    DEFAULT_USER_AGENT = "mkroman-dr-sentinel / #{VERSION} (github.com/mkroman/dr-sentinel)"

    def self.load_models!
      require_relative './sentinel/models/feed'
      require_relative './sentinel/models/feed_entry'
      require_relative './sentinel/models/http_request'
      # require_relative './sentinel/models/article'
    end
  end
end

