# frozen_string_literal: true

module DR
  module Sentinel
    class HTTPRequest < Sequel::Model
      one_to_many :article
      one_to_many :feed_entry

      plugin :timestamps
    end
  end
end
