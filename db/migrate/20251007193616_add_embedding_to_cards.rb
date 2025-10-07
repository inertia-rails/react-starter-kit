# frozen_string_literal: true

class AddEmbeddingToCards < ActiveRecord::Migration[8.0]
  def change
    add_column :cards, :embedding, :decimal, array: true, precision: 8, scale: 7
  end
end
