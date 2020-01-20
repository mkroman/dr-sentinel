# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table :feed_entries do
      rename_column :request_id, :http_request_id
      add_foreign_key [:http_request_id], :http_requests
    end
  end

  down do
    alter_table :feed_entries do
      drop_foreign_key [:http_request_id]
      rename_column :http_request_id, :request_id
    end
  end
end
