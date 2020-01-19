# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table :feeds do
      add_column :refresh_interval, Integer, default: 60
    end
  end

  down do
    alter_table :feeds do
      drop_column :refresh_interval
    end
  end
end
