# frozen_string_literal: true

module DR
  module Sentinel
    class FeedEntry < Sequel::Model
      many_to_one :feed
      many_to_one :http_request, class: 'DR::Sentinel::HTTPRequest'

      plugin :timestamps
    end
  end
end
