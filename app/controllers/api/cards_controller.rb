# frozen_string_literal: true

module Api
  class CardsController < ApplicationController
    skip_before_action :authenticate, only: [:autocomplete, :search, :keywords, :types]

    def types
      # Get all unique card types from type_line, split by spaces and dashes
      # This extracts individual types like "Creature", "Legendary", "Goblin", etc.
      types = Card.connection.select_values(
        <<-SQL
          SELECT DISTINCT unnest(
            string_to_array(
              regexp_replace(type_line, '[—–-]', ' ', 'g'),
              ' '
            )
          ) as card_type
          FROM cards
          WHERE type_line IS NOT NULL
          ORDER BY card_type
        SQL
      ).reject(&:blank?)

      render json: types
    rescue StandardError => e
      Rails.logger.error("Types fetch error: #{e.message}")
      render json: {error: "Failed to fetch types"}, status: :internal_server_error
    end

    def keywords
      # Get all unique keywords from cards, sorted alphabetically
      # keywords is stored as JSONB, so we use jsonb_array_elements_text
      keywords = Card.connection.select_values(
        "SELECT DISTINCT jsonb_array_elements_text(keywords) as keyword FROM cards WHERE keywords IS NOT NULL AND jsonb_array_length(keywords) > 0 ORDER BY keyword"
      )

      render json: keywords
    rescue StandardError => e
      Rails.logger.error("Keywords fetch error: #{e.message}")
      render json: {error: "Failed to fetch keywords"}, status: :internal_server_error
    end

    def autocomplete
      query = params[:q]

      if query.blank?
        return render json: []
      end

      search_service = Search::CardSearch.new
      results = search_service.autocomplete(query, limit: params[:limit]&.to_i || 10)

      render json: results
    rescue StandardError => e
      Rails.logger.error("Autocomplete error: #{e.message}")
      render json: {error: "Search failed"}, status: :internal_server_error
    end

    def search
      query = params[:q]
      page = params[:page]&.to_i || 1
      per_page = params[:per_page]&.to_i || 20
      search_mode = params[:search_mode] || "auto"

      # Limit per_page to reasonable values
      per_page = [[per_page, 1].max, 100].min

      # Validate search_mode
      valid_modes = %w[auto keyword semantic hybrid]
      search_mode = "auto" unless valid_modes.include?(search_mode)

      filters = build_filters

      search_service = Search::CardSearch.new
      results = search_service.search(query, filters: filters, page: page, per_page: per_page, search_mode: search_mode)

      render json: results
    rescue StandardError => e
      Rails.logger.error("Search error: #{e.message}")
      render json: {
        error: "Search failed",
        results: [],
        total: 0,
        page: page,
        per_page: per_page,
        total_pages: 0
      }, status: :internal_server_error
    end

    private

    def build_filters
      filters = {}

      # Color identity filter
      if params[:colors].present?
        filters[:colors] = Array(params[:colors])
        filters[:color_match] = params[:color_match] if params[:color_match].present?
      end

      # CMC filters
      filters[:cmc_min] = params[:cmc_min] if params[:cmc_min].present?
      filters[:cmc_max] = params[:cmc_max] if params[:cmc_max].present?

      # Type filter
      filters[:types] = Array(params[:types]) if params[:types].present?

      # Format legality filter
      filters[:formats] = Array(params[:formats]) if params[:formats].present?

      # Keywords filter
      filters[:keywords] = Array(params[:keywords]) if params[:keywords].present?

      # Layout filter
      filters[:layout] = params[:layout] if params[:layout].present?

      # Reserved list filter
      filters[:reserved] = params[:reserved] if params[:reserved].present?

      # Rarity filter
      filters[:rarities] = Array(params[:rarities]) if params[:rarities].present?

      # Power/Toughness filters
      filters[:power_min] = params[:power_min] if params[:power_min].present?
      filters[:power_max] = params[:power_max] if params[:power_max].present?
      filters[:toughness_min] = params[:toughness_min] if params[:toughness_min].present?
      filters[:toughness_max] = params[:toughness_max] if params[:toughness_max].present?

      # Loyalty filters
      filters[:loyalty_min] = params[:loyalty_min] if params[:loyalty_min].present?
      filters[:loyalty_max] = params[:loyalty_max] if params[:loyalty_max].present?

      # Popularity ranking filters
      filters[:edhrec_rank_min] = params[:edhrec_rank_min] if params[:edhrec_rank_min].present?
      filters[:edhrec_rank_max] = params[:edhrec_rank_max] if params[:edhrec_rank_max].present?
      filters[:penny_rank_min] = params[:penny_rank_min] if params[:penny_rank_min].present?
      filters[:penny_rank_max] = params[:penny_rank_max] if params[:penny_rank_max].present?

      # Release date filters
      filters[:released_after] = params[:released_after] if params[:released_after].present?
      filters[:released_before] = params[:released_before] if params[:released_before].present?

      # Platform/games filters
      filters[:games] = Array(params[:games]) if params[:games].present?
      filters[:on_arena] = params[:on_arena] if params[:on_arena].present?
      filters[:on_mtgo] = params[:on_mtgo] if params[:on_mtgo].present?

      # Mana production filters
      filters[:produced_mana] = Array(params[:produced_mana]) if params[:produced_mana].present?
      filters[:color_indicator] = Array(params[:color_indicator]) if params[:color_indicator].present?

      # Finishes filter
      filters[:finishes] = Array(params[:finishes]) if params[:finishes].present?

      # Printing-level filters
      filters[:artists] = Array(params[:artists]) if params[:artists].present?
      filters[:sets] = Array(params[:sets]) if params[:sets].present?
      filters[:frames] = Array(params[:frames]) if params[:frames].present?
      filters[:border_colors] = Array(params[:border_colors]) if params[:border_colors].present?
      filters[:frame_effects] = Array(params[:frame_effects]) if params[:frame_effects].present?
      filters[:promo_types] = Array(params[:promo_types]) if params[:promo_types].present?

      # Boolean characteristic filters
      filters[:oversized] = params[:oversized] if params[:oversized].present?
      filters[:promo] = params[:promo] if params[:promo].present?
      filters[:reprint] = params[:reprint] if params[:reprint].present?
      filters[:variation] = params[:variation] if params[:variation].present?
      filters[:digital] = params[:digital] if params[:digital].present?
      filters[:booster] = params[:booster] if params[:booster].present?
      filters[:story_spotlight] = params[:story_spotlight] if params[:story_spotlight].present?
      filters[:content_warning] = params[:content_warning] if params[:content_warning].present?
      filters[:game_changer] = params[:game_changer] if params[:game_changer].present?

      # Derived color identity filters
      filters[:colorless] = params[:colorless] if params[:colorless].present?
      filters[:mono_color] = params[:mono_color] if params[:mono_color].present?
      filters[:multicolor] = params[:multicolor] if params[:multicolor].present?

      # Price filters
      filters[:price_usd_min] = params[:price_usd_min] if params[:price_usd_min].present?
      filters[:price_usd_max] = params[:price_usd_max] if params[:price_usd_max].present?
      filters[:price_usd_foil_min] = params[:price_usd_foil_min] if params[:price_usd_foil_min].present?
      filters[:price_usd_foil_max] = params[:price_usd_foil_max] if params[:price_usd_foil_max].present?
      filters[:price_eur_min] = params[:price_eur_min] if params[:price_eur_min].present?
      filters[:price_eur_max] = params[:price_eur_max] if params[:price_eur_max].present?
      filters[:price_tix_min] = params[:price_tix_min] if params[:price_tix_min].present?
      filters[:price_tix_max] = params[:price_tix_max] if params[:price_tix_max].present?

      # Sort order
      filters[:sort] = params[:sort] if params[:sort].present?

      # Include tokens filter (allows tokens in search results)
      filters[:include_tokens] = params[:include_tokens] if params[:include_tokens].present?

      filters
    end
  end
end
