# frozen_string_literal: true

module DR
  module Sentinel
    class FeedEntry < Sequel::Model
      many_to_one :feed

      def self.new_from_rss_item item
        new(
          guid: item.guid.content,
          description: item.description
        )
      end
    end
  end
end
