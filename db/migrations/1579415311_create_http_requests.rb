# frozen_string_literal: true

Sequel.migration do
  up do
    create_table :http_requests do
      primary_key :id

      String :request_url # The initial request URL
      String :version # HTTP version
      Integer :response_code # The response code
      File :response_headers_json
      File :response_body
      String :compression, required: true # usually 'zstd'

      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, default: Sequel::CURRENT_TIMESTAMP
    end
  end

  down do
    drop_table :http_requests
  end
end
