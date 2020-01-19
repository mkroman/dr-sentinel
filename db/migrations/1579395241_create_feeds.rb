# frozen_string_literal: true

Sequel.migration do
  up do
    create_table :feeds do
      primary_key :id

      String :name
      String :url, unique: true
      TrueClass :active, default: true

      DateTime :checked_at
      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, default: Sequel::CURRENT_TIMESTAMP
    end
  end

  down do
    drop_table :feeds
  end
end
