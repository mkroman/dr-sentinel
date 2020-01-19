# frozen_string_literal: true

module DR
  module Sentinel
    class Feed < Sequel::Model
      plugin :timestamps
    end
  end
end

