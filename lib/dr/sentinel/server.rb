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
        @config_path = config_path
      end

      # Starts polling the news feed for changes.
      # This is blocking operation.
      def run
        @polling = true

        while @polling
        end
      end
    end
  end
end

