# frozen_string_literal: true

class CreateOpensearchMigrations < ActiveRecord::Migration[8.0]
  def change
    create_table :opensearch_migrations do |t|
      t.string :version, null: false
      t.string :name, null: false
      t.datetime :applied_at, null: false

      t.timestamps
    end

    add_index :opensearch_migrations, :version, unique: true
  end
end
