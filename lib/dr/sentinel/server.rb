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

        # Save the HTTP request to the database
        http_request = save_httpx_response response, feed.url, response_body

        if response.status == 200
          parsed_feed = RSS::Parser.parse response_body
          feed_entries = prepare_feed_entries parsed_feed, feed

          Database.transaction do
            feed_entries.each do |entry|
              entry.feed = feed
              entry.request = http_request
              entry.save
            end
          end
        else
          @logger.error "Unexpected response status #{response.status} when requesting #{feed.url}"
        end

        if response.status == 200
          # Update the feeds checked_at time
          feed.update checked_at: DateTime.now
        end
      end

      # Takes an RSS/Atom feed/channel and looks up which items aren't already
      # in the database, and then it creates a list of unsaved feed entry
      # instances for the missing items, ready to be saved.
      #
      # @param [RSS:Rss, RSS::Atom::Feed] atom_or_rss_feed rss or atom feed
      # @param [Feed] feed_instance feed model instance
      #
      # @return [Array<FeedEntry>] list of unsaved feed entries ready to be
      #   saved.
      def prepare_feed_entries atom_or_rss_feed, feed_instance
        items = feed_to_items_hash atom_or_rss_feed
        entries = FeedEntry
                  .select(:guid)
                  .where(guid: items.keys, feed: feed_instance)
                  .all
        existing_guids = entries.map &:guid
        nonexisting_items = items.reject { |guid, _| existing_guids.include? guid }

        raise NotImplementedError unless atom_or_rss_feed.is_a? RSS::Rss

        nonexisting_items.map { |_, item| feed_entry_from_rss_item item }
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
          compression: "zstd/#{Zstd.zstd_version}",
          response_code: response.status,
          response_body: compressed_body,
          response_headers_json: Zstd.compress(response.headers.to_hash.to_json)
        )

        request.save
      end

      # Takes an RSS/Atom feed/channel and returns the items as a hash where the
      # key is the items GUID and the value is the item.
      #
      # @param [RSS:Rss, RSS::Atom::Feed] feed rss or atom feed.
      def feed_to_items_hash feed
        if feed.is_a? RSS::Rss
          feed.items.map { |item| [item.guid.content, item] }.to_h
        else
          feed.items.map { |item| [item.id, item] }.to_h
        end
      end

      # Returns headers that is used by default for each outgoing request.
      def default_headers
        {
          'User-Agent' => http_user_agent
        }
      end

      # Creates a new unsaved +FeedEntry+ with populated columns from the
      #   provided +item+.
      #
      # @param [RSS::Rss::Channel::Item] item the RSS item from which data will
      #   be populated.
      #
      # @return [FeedEntry] unsaved FeedEntry with columns populated from +item+
      def feed_entry_from_rss_item item
        FeedEntry.new(
          guid: item.guid.content,
          link: item.link,
          title: item.title,
          description: item.description,
          published_at: item.pubDate
        )
      end
    end
  end
end
