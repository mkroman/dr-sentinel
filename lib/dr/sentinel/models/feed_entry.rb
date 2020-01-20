# frozen_string_literal: true

module DR
  module Sentinel
    class FeedEntry < Sequel::Model
      many_to_one :feed
      many_to_one :request, left_key: :request_id, class: 'DR::Sentinel::HTTPRequest'

      plugin :timestamps
    end
  end
end
