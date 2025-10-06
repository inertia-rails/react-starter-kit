# frozen_string_literal: true

module Search
  class CardIndexer < Base
    def create_index
      return true if index_exists?

      client.indices.create(
        index: index_name,
        body: index_configuration
      )
      Rails.logger.info("OpenSearch: Created index '#{index_name}'")
      true
    rescue StandardError => e
      Rails.logger.error("OpenSearch: Failed to create index: #{e.message}")
      false
    end

    def delete_index
      return true unless index_exists?

      client.indices.delete(index: index_name)
      Rails.logger.info("OpenSearch: Deleted index '#{index_name}'")
      true
    rescue StandardError => e
      Rails.logger.error("OpenSearch: Failed to delete index: #{e.message}")
      false
    end

    def index_card(card)
      client.index(
        index: index_name,
        id: card.id,
        body: card_document(card)
      )
      true
    rescue StandardError => e
      Rails.logger.error("OpenSearch: Failed to index card #{card.id}: #{e.message}")
      false
    end

    def delete_card(card_id)
      client.delete(
        index: index_name,
        id: card_id
      )
      true
    rescue OpenSearch::Transport::Transport::Errors::NotFound
      true # Already deleted
    rescue StandardError => e
      Rails.logger.error("OpenSearch: Failed to delete card #{card_id}: #{e.message}")
      false
    end

    def bulk_index(cards)
      return true if cards.empty?

      body = cards.flat_map do |card|
        [
          {index: {_index: index_name, _id: card.id}},
          card_document(card)
        ]
      end

      response = client.bulk(body: body)

      if response["errors"]
        failed_items = response["items"].select { |item| item.dig("index", "error") }
        Rails.logger.error("OpenSearch: Bulk index had #{failed_items.count} errors")
        failed_items.each do |item|
          Rails.logger.error("OpenSearch: Error for card #{item.dig("index", "_id")}: #{item.dig("index", "error", "reason")}")
        end
        return false
      end

      true
    rescue StandardError => e
      Rails.logger.error("OpenSearch: Bulk index failed: #{e.message}")
      false
    end

    def refresh_index
      client.indices.refresh(index: index_name)
    rescue StandardError => e
      Rails.logger.error("OpenSearch: Failed to refresh index: #{e.message}")
      false
    end

    def index_stats
      return {} unless index_exists?

      stats = client.indices.stats(index: index_name)
      {
        document_count: stats.dig("indices", index_name, "total", "docs", "count") || 0,
        size_in_bytes: stats.dig("indices", index_name, "total", "store", "size_in_bytes") || 0
      }
    rescue StandardError => e
      Rails.logger.error("OpenSearch: Failed to get index stats: #{e.message}")
      {}
    end

    def update_mapping
      return false unless index_exists?

      client.indices.put_mapping(
        index: index_name,
        body: {
          properties: {
            lang: {
              type: "keyword"
            }
          }
        }
      )
      Rails.logger.info("OpenSearch: Updated mapping for index '#{index_name}'")
      true
    rescue StandardError => e
      Rails.logger.error("OpenSearch: Failed to update mapping: #{e.message}")
      false
    end

    def update_all_documents_with_lang
      return false unless index_exists?

      # Use update_by_query to add lang field to all documents
      # The field should already exist in _source from previous indexing
      response = client.update_by_query(
        index: index_name,
        body: {
          script: {
            source: "ctx._source.lang = ctx._source.lang ?: 'en'",
            lang: "painless"
          },
          query: {
            match_all: {}
          }
        },
        conflicts: "proceed",
        wait_for_completion: true,
        refresh: true
      )

      updated = response["updated"] || 0
      Rails.logger.info("OpenSearch: Updated #{updated} documents with lang field")
      true
    rescue StandardError => e
      Rails.logger.error("OpenSearch: Failed to update documents: #{e.message}")
      false
    end

    private

    def index_configuration
      {
        settings: {
          number_of_shards: 1,
          number_of_replicas: 0,
          # Enable k-NN for vector search
          "index.knn": true,
          analysis: {
            analyzer: {
              card_name_autocomplete: {
                type: "custom",
                tokenizer: "standard",
                filter: ["lowercase", "card_name_edge_ngram"]
              },
              card_name_search: {
                type: "custom",
                tokenizer: "standard",
                filter: ["lowercase"]
              }
            },
            filter: {
              card_name_edge_ngram: {
                type: "edge_ngram",
                min_gram: 2,
                max_gram: 20
              }
            }
          }
        },
        mappings: {
          properties: {
            name: {
              type: "text",
              fields: {
                autocomplete: {
                  type: "text",
                  analyzer: "card_name_autocomplete",
                  search_analyzer: "card_name_search"
                },
                keyword: {
                  type: "keyword"
                }
              }
            },
            oracle_text: {
              type: "text"
            },
            type_line: {
              type: "text",
              fields: {
                keyword: {
                  type: "keyword"
                }
              }
            },
            mana_cost: {
              type: "keyword"
            },
            cmc: {
              type: "float"
            },
            colors: {
              type: "keyword"
            },
            color_identity: {
              type: "keyword"
            },
            keywords: {
              type: "keyword"
            },
            layout: {
              type: "keyword"
            },
            rarity: {
              type: "keyword"
            },
            reserved: {
              type: "boolean"
            },
            # Card faces for multi-faced cards
            card_faces: {
              type: "nested",
              properties: {
                name: {type: "text"},
                mana_cost: {type: "keyword"},
                type_line: {type: "text"},
                oracle_text: {type: "text"},
                power: {type: "keyword"},
                toughness: {type: "keyword"},
                loyalty: {type: "keyword"},
                colors: {type: "keyword"},
                image_uris: {type: "object", enabled: false}
              }
            },
            # Legalities as nested objects for filtering
            legalities: {
              type: "object",
              properties: {
                standard: {type: "keyword"},
                pioneer: {type: "keyword"},
                modern: {type: "keyword"},
                legacy: {type: "keyword"},
                vintage: {type: "keyword"},
                commander: {type: "keyword"},
                pauper: {type: "keyword"}
              }
            },
            # Power/toughness for creatures
            power: {
              type: "keyword"
            },
            toughness: {
              type: "keyword"
            },
            loyalty: {
              type: "keyword"
            },
            # Platform availability
            games: {
              type: "keyword"
            },
            arena_id: {
              type: "integer"
            },
            mtgo_id: {
              type: "integer"
            },
            # Mana production
            produced_mana: {
              type: "keyword"
            },
            color_indicator: {
              type: "keyword"
            },
            # Boolean characteristics
            oversized: {
              type: "boolean"
            },
            promo: {
              type: "boolean"
            },
            reprint: {
              type: "boolean"
            },
            variation: {
              type: "boolean"
            },
            digital: {
              type: "boolean"
            },
            booster: {
              type: "boolean"
            },
            story_spotlight: {
              type: "boolean"
            },
            content_warning: {
              type: "boolean"
            },
            game_changer: {
              type: "boolean"
            },
            # Popularity rankings
            edhrec_rank: {
              type: "integer"
            },
            penny_rank: {
              type: "integer"
            },
            # Aggregated printing data
            artists: {
              type: "keyword"
            },
            sets: {
              type: "keyword"
            },
            frames: {
              type: "keyword"
            },
            border_colors: {
              type: "keyword"
            },
            frame_effects: {
              type: "keyword"
            },
            promo_types: {
              type: "keyword"
            },
            # Price data (aggregated from printings)
            price_usd: {
              type: "float"
            },
            price_usd_foil: {
              type: "float"
            },
            price_eur: {
              type: "float"
            },
            price_tix: {
              type: "float"
            },
            # Semantic search vector field
            embedding: {
              type: "knn_vector",
              dimension: 1536,
              method: {
                name: "hnsw",
                space_type: "cosinesimil",
                engine: "lucene",
                parameters: {
                  ef_construction: 256, # Increased for better index quality (slower indexing, better recall)
                  m: 24 # Increased for better recall at query time (more memory, better results)
                }
              }
            },
            # Image data
            image_uris: {
              type: "object",
              enabled: false
            },
            # Finish/foiling
            finishes: {
              type: "keyword"
            },
            # Language
            lang: {
              type: "keyword"
            },
            # Metadata
            released_at: {
              type: "date"
            },
            updated_at: {
              type: "date"
            }
          }
        }
      }
    end

    def card_document(card)
      # Get printing for image data with the following priority:
      # 1. Default printing (marked by Scryfall's default_cards dataset)
      # 2. English printing with nonfoil finish
      # 3. Any English printing
      # 4. Any printing at all
      english_printings = card.card_printings.select { |p| p.lang == "en" }
      printing = card.card_printings.find { |p| p.is_default } ||
                 english_printings.find { |p| p.finishes&.include?("nonfoil") } ||
                 english_printings.first ||
                 card.card_printings.first

      # For multi-faced cards without image_uris on printings, use card_faces
      image_uris = if card.card_faces.any? && card.card_faces.first.image_uris.present?
        card.card_faces.first.image_uris
      elsif printing&.image_uris.present?
        printing.image_uris
      else
        {}
      end

      # Collect available finishes from printings, prioritizing nonfoil
      finishes = card.card_printings.flat_map { |p| p.finishes || [] }.uniq
      finishes = ["nonfoil"] if finishes.empty? # Default to nonfoil
      # Put nonfoil first if available so it's the default finish
      finishes = finishes.sort_by { |f| f == "nonfoil" ? 0 : 1 }

      # Get rarity from first printing (prioritize the same printing we use for images)
      rarity = printing&.rarity

      # Aggregate printing data
      printing_data = aggregate_printing_data(card)
      price_data = aggregate_price_data(card)

      doc = {
        name: card.name,
        oracle_text: card.oracle_text,
        type_line: card.type_line,
        mana_cost: card.mana_cost,
        cmc: card.cmc,
        colors: card.colors || [],
        color_identity: card.color_identity || [],
        keywords: card.keywords || [],
        layout: card.layout,
        rarity: rarity,
        power: card.power,
        toughness: card.toughness,
        loyalty: card.loyalty,
        reserved: card.reserved,
        image_uris: image_uris,
        finishes: finishes,
        card_faces: card.card_faces.map { |face| card_face_document(face) },
        legalities: card_legalities_document(card),
        lang: card.lang,
        released_at: card.released_at,
        updated_at: card.updated_at,
        # Platform availability
        games: card.games || [],
        arena_id: card.arena_id,
        mtgo_id: card.mtgo_id,
        # Mana production
        produced_mana: card.produced_mana || [],
        color_indicator: card.color_indicator || [],
        # Boolean characteristics
        oversized: card.oversized,
        promo: card.promo,
        reprint: card.reprint,
        variation: card.variation,
        digital: card.digital,
        booster: card.booster,
        story_spotlight: card.story_spotlight,
        content_warning: card.content_warning,
        game_changer: card.game_changer,
        # Popularity rankings
        edhrec_rank: card.edhrec_rank,
        penny_rank: card.penny_rank,
        # Aggregated printing data
        artists: printing_data[:artists],
        sets: printing_data[:sets],
        frames: printing_data[:frames],
        border_colors: printing_data[:border_colors],
        frame_effects: printing_data[:frame_effects],
        promo_types: printing_data[:promo_types],
        # Price data
        price_usd: price_data[:usd],
        price_usd_foil: price_data[:usd_foil],
        price_eur: price_data[:eur],
        price_tix: price_data[:tix]
      }

      # Generate embedding for semantic search (optional, gracefully handle failures)
      # Skip if card already has embeddings generated (unless forced to regenerate)
      should_generate = ENV["GENERATE_EMBEDDINGS"] == "true" &&
                        (card.embeddings_generated_at.nil? || ENV["FORCE_REGENERATE_EMBEDDINGS"] == "true")

      if should_generate
        begin
          embedding = EmbeddingService.embed_card(card)
          doc[:embedding] = embedding if embedding.present?
        rescue StandardError => e
          Rails.logger.warn("Failed to generate embedding for card #{card.id}: #{e.message}")
          # Continue without embedding
        end
      end

      doc
    end

    def card_face_document(face)
      {
        name: face.name,
        mana_cost: face.mana_cost,
        type_line: face.type_line,
        oracle_text: face.oracle_text,
        power: face.power,
        toughness: face.toughness,
        loyalty: face.loyalty,
        colors: face.colors || [],
        image_uris: face.image_uris || {}
      }
    end

    def card_legalities_document(card)
      legalities = {}
      card.card_legalities.each do |legality|
        legalities[legality.format] = legality.status
      end
      legalities
    end

    def aggregate_printing_data(card)
      printings = card.card_printings

      {
        artists: printings.map(&:artist).compact.uniq,
        sets: printings.map { |p| p.card_set.code }.compact.uniq,
        frames: printings.map(&:frame).compact.uniq,
        border_colors: printings.map(&:border_color).compact.uniq,
        frame_effects: printings.flat_map { |p| p.frame_effects || [] }.uniq,
        promo_types: printings.flat_map { |p| p.promo_types || [] }.uniq
      }
    end

    def aggregate_price_data(card)
      printings = card.card_printings

      # Get lowest price for each price type across all printings
      usd_prices = printings.filter_map { |p| p.prices&.dig("usd")&.to_f }.compact
      usd_foil_prices = printings.filter_map { |p| p.prices&.dig("usd_foil")&.to_f }.compact
      eur_prices = printings.filter_map { |p| p.prices&.dig("eur")&.to_f }.compact
      tix_prices = printings.filter_map { |p| p.prices&.dig("tix")&.to_f }.compact

      {
        usd: usd_prices.min,
        usd_foil: usd_foil_prices.min,
        eur: eur_prices.min,
        tix: tix_prices.min
      }
    end
  end
end
