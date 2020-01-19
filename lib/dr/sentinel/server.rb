# frozen_string_literal: true

module DR
  module Sentinel
    class Server
      # @return [Boolean] true if the server is polling for changes.
      attr_accessor :polling

      # Create a new +Server+ instance that's ready to start polling
      def initialize config_path, config
        @http = HTTPX.plugin :compression
        @config = config
        @polling = false
        @logging = Logging.logger[self.class.name]
        @config_path = config_path
      end

      # Stop polling for feed changes.
      def stop
        @logging.debug 'Stopping polling'

        @polling = false
      end

      # Starts polling the news feed for changes.
      # This is blocking operation.
      def run
        @logging.debug 'Starting polling'
        @polling = true

        while @polling
          pending_feeds = Feed.all.select(&:pending_refresh?)

          pending_feeds.each do |feed|
            @logging.debug "Requesting `#{feed.url}'"
          end

          sleep 1
        end
      end
    end
  end
end

