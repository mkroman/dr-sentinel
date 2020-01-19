# frozen_string_literal: true

module DR
  module Sentinel
    class Server
      # @return [Boolean] true if the server is polling for changes.
      attr_accessor :polling

      # Create a new +Server+ instance that's ready to start polling
      def initialize config_path, config
        @http = HTTPX.plugins :compression, :retries, :follow_redirects
        @config = config
        @polling = false
        @logging = Logging.logger[self.class.name]
        @config_path = config_path
      end

      # Helper method that returns the configured user agent used for HTTP
      # requests.
      #
      # @return [String] the configured user agent
      def http_user_agent
        http_config = @config.fetch 'http', {}

        http_config.fetch 'user_agent', DEFAULT_USER_AGENT
      end

      # Stops polling for feed changes.
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
          pending_feeds = Feed.all.select &:pending_refresh?

          pending_feeds.each do |feed|
            @logging.debug "Requesting `#{feed.url}'"

            update_feed feed
          end

          sleep 1
        end
      end

      # Refreshes the given +feed+ and process any new entries from it.
      #
      # @param feed [Feed] the feed to process
      def update_feed feed
        response = @http.headers('user-agent' => http_user_agent).get feed.url

        if response.status == 200
          puts "Status: #{response.status}"
          puts "Headers: #{response.headers.inspect}"
          puts "Body:"
          puts response.body

          # Update the feeds checked_at time
          feed.checked_at = DateTime.now
          feed.save
        else
          @logger.error "Unexpected response status #{response.status} when requesting #{feed.url}"
        end
      end

    private

      # Returns headers that is used by default for each outgoing request.
      def default_headers
        {
          'User-Agent' => http_user_agent
        }
      end
    end
  end
end

