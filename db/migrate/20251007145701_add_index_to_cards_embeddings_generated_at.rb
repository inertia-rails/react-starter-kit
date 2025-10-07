# frozen_string_literal: true

class AddIndexToCardsEmbeddingsGeneratedAt < ActiveRecord::Migration[8.0]
  def change
    add_index :cards, :embeddings_generated_at
  end
end
