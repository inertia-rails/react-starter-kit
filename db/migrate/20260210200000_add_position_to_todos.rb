# frozen_string_literal: true

class AddPositionToTodos < ActiveRecord::Migration[8.0]
  class MigrationTodo < ApplicationRecord
    self.table_name = "todos"
  end

  def up
    add_column :todos, :position, :integer, null: false, default: 1
    add_index :todos, [:user_id, :position]

    MigrationTodo.reset_column_information

    say_with_time "Backfilling todo positions by creation order" do
      MigrationTodo.distinct.pluck(:user_id).each do |user_id|
        MigrationTodo.where(user_id: user_id).order(:created_at, :id).each_with_index do |todo, index|
          todo.update_columns(position: index + 1)
        end
      end
    end
  end

  def down
    remove_index :todos, [:user_id, :position]
    remove_column :todos, :position
  end
end
