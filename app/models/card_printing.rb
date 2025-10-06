# frozen_string_literal: true

class CardPrinting < ApplicationRecord
  # Class attribute to control OpenSearch callbacks during bulk operations
  class_attribute :skip_opensearch_callbacks, default: false

  # Associations
  belongs_to :card
  belongs_to :card_set

  # OpenSearch indexing callbacks - trigger when default printing changes
  after_commit :reindex_card_in_opensearch, if: :should_reindex_card?, unless: :skip_opensearch_callbacks?

  # Validations
  validates :collector_number, presence: true
  validates :rarity, presence: true, inclusion: {in: %w[common uncommon rare mythic special bonus]}
  validates :border_color, presence: true
  validates :card_id, uniqueness: {scope: [:card_set_id, :collector_number]}

  # Scopes
  scope :by_rarity, ->(rarity) { where(rarity: rarity) }
  scope :common, -> { by_rarity("common") }
  scope :uncommon, -> { by_rarity("uncommon") }
  scope :rare, -> { by_rarity("rare") }
  scope :mythic, -> { by_rarity("mythic") }
  scope :special, -> { by_rarity("special") }

  scope :foil_only, -> { where("'foil' = ANY(finishes) AND NOT ('nonfoil' = ANY(finishes))") }
  scope :nonfoil_only, -> { where("'nonfoil' = ANY(finishes) AND NOT ('foil' = ANY(finishes))") }
  scope :has_foil, -> { where("'foil' = ANY(finishes)") }
  scope :has_nonfoil, -> { where("'nonfoil' = ANY(finishes)") }

  scope :full_art, -> { where(full_art: true) }
  scope :textless, -> { where(textless: true) }
  scope :promo, -> { where(promo: true) }
  scope :reprint, -> { where(reprint: true) }
  scope :first_printing, -> { where(reprint: false) }

  scope :by_artist, ->(artist_name) { where("artist ILIKE ?", "%#{artist_name}%") }

  scope :with_price_data, -> { where("prices IS NOT NULL AND prices != '{}'::jsonb") }

  # Price helpers
  def price_usd
    prices&.dig("usd")&.to_f
  end

  def price_usd_foil
    prices&.dig("usd_foil")&.to_f
  end

  def price_eur
    prices&.dig("eur")&.to_f
  end

  def price_tix
    prices&.dig("tix")&.to_f
  end

  def lowest_price
    [price_usd, price_usd_foil].compact.min
  end

  def has_price_data?
    prices.present? && prices.any? { |_k, v| v.present? }
  end

  # Image helpers
  def image_uri(size = "normal")
    image_uris&.dig(size) || image_uris&.dig("normal")
  end

  def small_image
    image_uri("small")
  end

  def normal_image
    image_uri("normal")
  end

  def large_image
    image_uri("large")
  end

  def art_crop_image
    image_uri("art_crop")
  end

  def border_crop_image
    image_uri("border_crop")
  end

  # Finish helpers
  def foil_available?
    finishes&.include?("foil")
  end

  def nonfoil_available?
    finishes&.include?("nonfoil")
  end

  def etched_available?
    finishes&.include?("etched")
  end

  def glossy_available?
    finishes&.include?("glossy")
  end

  # Display helpers
  def display_name
    printed_name || card.name
  end

  def set_name
    card_set.name
  end

  def set_code
    card_set.code
  end

  def skip_opensearch_callbacks?
    self.class.skip_opensearch_callbacks
  end

  private

  # Trigger reindex when is_default changes (default printing changes)
  def should_reindex_card?
    saved_change_to_is_default?
  end

  def reindex_card_in_opensearch
    OpenSearchCardUpdateJob.perform_later(card_id, "index")
  end
end
