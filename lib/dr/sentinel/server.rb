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

        response_body = response.body.to_s

        if response.status == 200
          parsed_feed = RSS::Parser.parse response_body

          case parsed_feed
          when RSS::Rss
            process_rss_feed parsed_feed, feed
          when RSS::Atom::Feed
            process_atom_feed parsed_feed, feed
          end
        else
          @logger.error "Unexpected response status #{response.status} when requesting #{feed.url}"
        end

        if response.status == 200
          # Update the feeds checked_at time
          feed.checked_at = DateTime.now
          feed.save
        end

        # Save the HTTP request to the database
        save_httpx_response response, feed.url, response_body
      end

      def process_rss_feed feed, feed_db_instance
        entries = {}

        feed.items.each do |item|
          entries[item.guid.content] = item
        end

        feed_entries = FeedEntry
                       .select(:guid)
                       .where(feed: feed_db_instance, guid: entries.keys)
                       .all
        feed_entry_guids = feed_entries.map &:guid
        new_entries = feed.items.reject { |item| feed_entry_guids.include?(item.guid.content) }

        puts "new entries: #{new_entries}"
      end

      def process_atom_feed _feed, _feed_db_instance
        @logging.warn 'atom support not implemented yet'
      end

    private

      # Saves the given httpx response to the database
      def save_httpx_response response, request_url, response_body
        compressed_body = Zstd.compress response_body

        @logging.debug "Size before compression: #{response_body.bytesize}"
        @logging.debug "Size after compression: #{compressed_body.bytesize}"

        request = HTTPRequest.new(
          version: response.version,
          request_url: request_url,
          compression: 'zstd',
          response_code: response.status,
          response_body: compressed_body,
          response_headers_json: Zstd.compress(response.headers.to_hash.to_json)
        )

        request.save
      end

      # Returns headers that is used by default for each outgoing request.
      def default_headers
        {
          'User-Agent' => http_user_agent
        }
      end
    end
  end
end
