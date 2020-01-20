# frozen_string_literal: true

Sequel.migration do
  up do
    create_table :articles do
      primary_key :id

      String :title
      String :article_html
      String :article_text
      String :compression

      foreign_key :feed_id, :feeds
      foreign_key :feed_entry_id, :feed_entries
      foreign_key :request_id, :http_requests

      Integer :parent_article_id

      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, default: Sequel::CURRENT_TIMESTAMP
    end
  end

  down do
    drop_table :articles
  end
end
