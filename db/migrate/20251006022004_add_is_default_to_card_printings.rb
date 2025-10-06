# frozen_string_literal: true

class AddIsDefaultToCardPrintings < ActiveRecord::Migration[8.0]
  def change
    add_column :card_printings, :is_default, :boolean, default: false, null: false
    add_index :card_printings, :is_default
  end
end
