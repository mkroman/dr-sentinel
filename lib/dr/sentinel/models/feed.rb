# frozen_string_literal: true

module DR
  module Sentinel
    class Feed < Sequel::Model

      # Returns whether the feed is ready for a refresh (i.e. the time since
      # last check exceeds the refresh interval.)
      #
      # @todo Make this a query modifier rather than an instance method for
      #   better performance.
      def pending_refresh?
        last_check = self.checked_at || DateTime.new
        time_offset = Time.now - self.refresh_interval

        return last_check.to_time < time_offset
      end

      plugin :timestamps
    end
  end
end

