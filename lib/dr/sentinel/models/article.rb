# frozen_string_literal: true

module DR
  module Sentinel
    class Article < Sequel::Model
      many_to_one :feed
      one_to_one :http_request
    end
  end
end
