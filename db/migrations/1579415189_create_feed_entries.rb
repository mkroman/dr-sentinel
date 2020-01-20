# frozen_string_literal: true

Sequel.migration do
  up do
    create_table :feed_entries do
      primary_key :id

      String :guid
      String :title
      String :link
      String :description
      DateTime :published_at

      Integer :feed_id
      Integer :request_id # HTTP request id
    end
  end

  down do
    drop_table :feed_entries
  end
end
