# frozen_string_literal: true

class AddLangToCardPrintings < ActiveRecord::Migration[8.0]
  def change
    add_column :card_printings, :lang, :string, default: "en", null: false
    add_index :card_printings, :lang
  end
end
