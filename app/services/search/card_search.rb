# frozen_string_literal: true

module Search
  class CardSearch < Base
    # Load MTG nickname mappings
    NICKNAMES = YAML.load_file(Rails.root.join("config/mtg_nicknames.yml")).freeze rescue {}

    def autocomplete(query, limit: 10)
      return [] if query.blank?

      search_body = {
        query: {
          bool: {
            should: [
              {
                match: {
                  "name.autocomplete": {
                    query: query,
                    boost: 2
                  }
                }
              },
              {
                match_phrase_prefix: {
                  name: {
                    query: query,
                    boost: 3
                  }
                }
              }
            ]
          }
        },
        _source: ["name", "type_line", "mana_cost"],
        size: limit
      }

      response = client.search(
        index: index_name,
        body: search_body
      )

      format_autocomplete_results(response)
    rescue StandardError => e
      Rails.logger.error("OpenSearch autocomplete failed: #{e.message}")
      []
    end

    def search(query, filters: {}, page: 1, per_page: 20, search_mode: "auto")
      # Check for nickname match and expand to official card name
      expanded_query = expand_nickname(query)

      # Determine which search mode to use
      mode = determine_search_mode(expanded_query, search_mode)

      search_body = case mode
      when "semantic"
        build_semantic_search_query(expanded_query, filters)
      when "hybrid"
        build_hybrid_search_query(expanded_query, filters)
      else
        build_search_query(expanded_query, filters)
      end

      search_body[:from] = (page - 1) * per_page
      search_body[:size] = per_page

      response = client.search(
        index: index_name,
        body: search_body
      )

      format_search_results(response, page, per_page)
    rescue OpenSearch::Transport::Transport::Errors::BadRequest => e
      # Handle k-NN field errors - fall back to keyword search
      if e.message.include?("not knn_vector type") || e.message.include?("Field 'embedding'")
        Rails.logger.warn("K-NN search failed (embeddings not available), falling back to keyword search: #{e.message}")
        # Retry with keyword search
        search_body = build_search_query(expanded_query, filters)
        search_body[:from] = (page - 1) * per_page
        search_body[:size] = per_page
        response = client.search(index: index_name, body: search_body)
        format_search_results(response, page, per_page)
      else
        Rails.logger.error("OpenSearch search failed: #{e.message}")
        {
          results: [],
          total: 0,
          page: page,
          per_page: per_page,
          total_pages: 0
        }
      end
    rescue StandardError => e
      Rails.logger.error("OpenSearch search failed: #{e.message}")
      {
        results: [],
        total: 0,
        page: page,
        per_page: per_page,
        total_pages: 0
      }
    end

    private

    # Check if query matches a known MTG nickname and expand to official card name
    def expand_nickname(query)
      return query if query.blank?

      # Normalize query for nickname lookup (lowercase, strip whitespace)
      normalized = query.strip.downcase

      # Check if it matches a nickname
      if NICKNAMES.key?(normalized)
        official_name = NICKNAMES[normalized]
        Rails.logger.debug("Expanded nickname '#{query}' to '#{official_name}'")
        return official_name
      end

      # Return original query if no nickname match
      query
    end

    def build_search_query(query, filters)
      query_clauses = []

      # Use build_filter_clauses to get all filters including defaults
      filter_clauses = build_filter_clauses(filters)

      # Text search across multiple fields
      if query.present?
        query_clauses << {
          multi_match: {
            query: query,
            fields: ["name^3", "oracle_text", "type_line^2", "card_faces.name^2", "card_faces.oracle_text"],
            type: "best_fields",
            fuzziness: "AUTO"
          }
        }
      end

      # All other filters are handled by build_filter_clauses

      # Build the final query with ranking boosts
      {
        query: {
          function_score: {
            query: {
              bool: {
                must: query_clauses.any? ? query_clauses : [{match_all: {}}],
                filter: filter_clauses
              }
            },
            functions: [
              # EDHREC popularity boost (lower rank = more popular)
              {
                filter: {exists: {field: "edhrec_rank"}},
                script_score: {
                  script: {
                    source: "Math.log10(10000.0 / Math.max(doc['edhrec_rank'].value, 1.0) + 1.0)",
                    lang: "painless"
                  }
                },
                weight: 1.5
              },
              # Recency boost for cards released in the last 2 years
              {
                filter: {range: {released_at: {gte: "now-2y"}}},
                weight: 1.3
              }
            ],
            score_mode: "sum",
            boost_mode: "multiply"
          }
        },
        sort: build_sort_options(filters[:sort]),
        _source: true
      }
    end

    def build_sort_options(sort_param)
      case sort_param
      when "name"
        [{"name.keyword": {order: "asc"}}]
      when "cmc"
        [{cmc: {order: "asc"}}, {"name.keyword": {order: "asc"}}]
      when "released"
        [{released_at: {order: "desc"}}]
      else
        ["_score", {"name.keyword": {order: "asc"}}]
      end
    end

    def format_autocomplete_results(response)
      hits = response.dig("hits", "hits") || []
      hits.map do |hit|
        source = hit["_source"]
        {
          id: hit["_id"],
          name: source["name"],
          type_line: source["type_line"],
          mana_cost: source["mana_cost"]
        }
      end
    end

    def format_search_results(response, page, per_page)
      hits = response.dig("hits", "hits") || []
      total = response.dig("hits", "total", "value") || 0

      results = hits.map do |hit|
        card_data = hit["_source"]
        # Remove embedding from results to reduce payload size
        card_data.delete("embedding")
        card_data.merge(
          id: hit["_id"],
          score: hit["_score"]
        )
      end

      {
        results: results,
        total: total,
        page: page,
        per_page: per_page,
        total_pages: (total.to_f / per_page).ceil
      }
    end

    # Determine which search mode to use based on query and mode parameter
    def determine_search_mode(query, search_mode)
      return search_mode unless search_mode == "auto"
      return "keyword" if query.blank?

      query_lower = query.downcase
      word_count = query.split.length

      # Exact card name patterns - use keyword for precision
      # Match patterns like "Lightning Bolt", "Black Lotus"
      # Capitalized words or quoted strings suggest exact names
      if query.match?(/^["'].*["']$/) || (word_count <= 4 && query.match?(/^[A-Z]/))
        return "keyword"
      end

      # Effect-based queries - use hybrid for semantic + keyword
      effect_phrases = [
        "cards that", "cards with", "spells that", "creatures that",
        "draw cards", "remove", "destroy", "exile", "counter",
        "sacrifice", "discard", "mill", "tutor", "ramp",
        "life gain", "lifelink", "flying", "trample", "haste",
        "triggers", "when", "whenever", "enters the battlefield",
        "dies", "attacks", "blocks"
      ]
      contains_effect = effect_phrases.any? { |phrase| query_lower.include?(phrase) }

      # Question words indicate natural language queries
      question_words = ["what", "how", "which", "who", "find me", "show me", "looking for"]
      contains_question = question_words.any? { |word| query_lower.include?(word) }

      # MTG slang/nicknames - use hybrid for semantic understanding
      slang_terms = ["dork", "wrath", "counterspell", "removal", "board wipe", "ramp", "tutor"]
      contains_slang = slang_terms.any? { |term| query_lower.include?(term) }

      # Descriptive queries (adjectives + nouns) suggest semantic
      descriptive_patterns = [
        "cheap", "expensive", "powerful", "best", "good", "bad",
        "fast", "slow", "efficient", "inefficient"
      ]
      contains_descriptive = descriptive_patterns.any? { |word| query_lower.include?(word) }

      # Decision logic
      if contains_effect || contains_question || contains_slang || contains_descriptive
        "hybrid" # Natural language or effect-based queries benefit from both
      elsif word_count > 5
        "hybrid" # Longer queries likely descriptive
      elsif word_count >= 2
        "keyword" # Short multi-word queries likely card names or types
      else
        "keyword" # Single word searches (card names, types)
      end
    end

    # Build a pure semantic search query using k-NN
    def build_semantic_search_query(query, filters)
      query_embedding = EmbeddingService.embed(query)

      # Fall back to keyword search if embedding fails
      return build_search_query(query, filters) if query_embedding.blank?

      filter_clauses = build_filter_clauses(filters)

      # Use script_score to combine k-NN similarity with popularity/recency boosts
      # k-NN query returns cosine similarity scores which we enhance with other factors
      search_query = {
        size: 20, # Will be overridden by caller
        query: {
          script_score: {
            query: {
              bool: {
                must: {
                  knn: {
                    embedding: {
                      vector: query_embedding,
                      k: 200 # Get more candidates for better recall
                    }
                  }
                },
                filter: filter_clauses
              }
            },
            script: {
              source: """
                // Start with k-NN similarity score
                double baseScore = _score;

                // Popularity boost (EDHREC rank)
                double popularityBoost = 1.0;
                if (doc.containsKey('edhrec_rank') && doc['edhrec_rank'].size() > 0) {
                  popularityBoost = Math.log10(10000.0 / Math.max(doc['edhrec_rank'].value, 1.0) + 1.0) * 1.5;
                }

                // Recency boost (cards from last 2 years)
                double recencyBoost = 1.0;
                if (doc.containsKey('released_at') && doc['released_at'].size() > 0) {
                  long releaseMillis = doc['released_at'].value.toInstant().toEpochMilli();
                  long now = new Date().getTime();
                  long twoYearsMs = 730L * 24L * 60L * 60L * 1000L;
                  if (now - releaseMillis < twoYearsMs) {
                    recencyBoost = 1.3;
                  }
                }

                // Combine: base similarity × popularity boost × recency boost
                return baseScore * popularityBoost * recencyBoost;
              """,
              lang: "painless"
            }
          }
        },
        sort: ["_score", {"name.keyword": {order: "asc"}}],
        _source: {excludes: ["embedding"]}
      }

      search_query
    end

    # Build a hybrid search query combining k-NN and keyword search
    def build_hybrid_search_query(query, filters)
      query_embedding = EmbeddingService.embed(query)

      # Fall back to keyword search if embedding fails
      return build_search_query(query, filters) if query_embedding.blank?

      filter_clauses = build_filter_clauses(filters)

      # Hybrid approach: Combine k-NN and keyword search using bool should with scripted boosting
      # This avoids the cosineSimilarity type casting issue by using separate k-NN and keyword queries
      {
        query: {
          script_score: {
            query: {
              bool: {
                should: [
                  # k-NN semantic search component
                  {
                    knn: {
                      embedding: {
                        vector: query_embedding,
                        k: 100 # Get top 100 candidates from k-NN
                      }
                    }
                  },
                  # Keyword search component
                  {
                    multi_match: {
                      query: query,
                      fields: ["name^3", "oracle_text", "type_line^2", "card_faces.name^2", "card_faces.oracle_text"],
                      type: "best_fields",
                      fuzziness: "AUTO"
                    }
                  }
                ],
                filter: filter_clauses,
                minimum_should_match: 1 # Need at least one match (k-NN or keyword)
              }
            },
            script: {
              source: """
                // Base score combines k-NN similarity and keyword relevance
                double baseScore = _score;

                // Popularity boost (EDHREC rank)
                double popularityBoost = 1.0;
                if (doc.containsKey('edhrec_rank') && doc['edhrec_rank'].size() > 0) {
                  popularityBoost = Math.log10(10000.0 / Math.max(doc['edhrec_rank'].value, 1.0) + 1.0) * 1.5;
                }

                // Recency boost (cards from last 2 years)
                double recencyBoost = 1.0;
                if (doc.containsKey('released_at') && doc['released_at'].size() > 0) {
                  long releaseMillis = doc['released_at'].value.toInstant().toEpochMilli();
                  long now = new Date().getTime();
                  long twoYearsMs = 730L * 24L * 60L * 60L * 1000L;
                  if (now - releaseMillis < twoYearsMs) {
                    recencyBoost = 1.3;
                  }
                }

                // Apply boosts to the combined score
                return baseScore * popularityBoost * recencyBoost;
              """,
              lang: "painless"
            }
          }
        },
        sort: ["_score", {"name.keyword": {order: "asc"}}],
        _source: {excludes: ["embedding"]}
      }
    end

    # Extract filter building logic for reuse
    def build_filter_clauses(filters)
      filter_clauses = []

      # Language filter - default to English unless specified
      lang = filters[:lang] || "en"
      filter_clauses << {term: {lang: lang}} if lang.present?

      # Default paper-only filter - exclude digital-only cards unless user explicitly filters for digital platforms
      # If user specifies arena or mtgo in games filter, allow those digital cards
      unless filters[:games].present? && (filters[:games].include?("arena") || filters[:games].include?("mtgo"))
        filter_clauses << {term: {games: "paper"}}
      end

      # Exclude non-playable layouts by default (tokens, art cards, emblems, etc.)
      # Allow if user explicitly includes tokens or searches for token type
      non_playable_layouts = ["token", "double_faced_token", "art_series", "emblem"]
      unless filters[:include_tokens] == "true" || filters[:types]&.any? { |t| t.downcase.include?("token") }
        filter_clauses << {
          bool: {
            must_not: {terms: {layout: non_playable_layouts}}
          }
        }
      end

      # Require cards to be playable in at least one format
      # This excludes unplayable cards like art cards that have no legality
      # Accept "legal", "restricted", or "banned" status (all indicate real, playable cards)
      # Cards like Black Lotus are "restricted" in Vintage, "banned" in Legacy but should still be searchable
      filter_clauses << {
        bool: {
          should: [
            {terms: {"legalities.standard": ["legal", "restricted", "banned"]}},
            {terms: {"legalities.pioneer": ["legal", "restricted", "banned"]}},
            {terms: {"legalities.modern": ["legal", "restricted", "banned"]}},
            {terms: {"legalities.legacy": ["legal", "restricted", "banned"]}},
            {terms: {"legalities.vintage": ["legal", "restricted", "banned"]}},
            {terms: {"legalities.commander": ["legal", "restricted", "banned"]}},
            {terms: {"legalities.oathbreaker": ["legal", "restricted", "banned"]}},
            {terms: {"legalities.brawl": ["legal", "restricted", "banned"]}},
            {terms: {"legalities.historic": ["legal", "restricted", "banned"]}},
            {terms: {"legalities.gladiator": ["legal", "restricted", "banned"]}},
            {terms: {"legalities.duel": ["legal", "restricted", "banned"]}},
            {terms: {"legalities.penny": ["legal", "restricted", "banned"]}},
            {terms: {"legalities.timeless": ["legal", "restricted", "banned"]}},
            {terms: {"legalities.alchemy": ["legal", "restricted", "banned"]}},
            {terms: {"legalities.pauper": ["legal", "restricted", "banned"]}},
            {terms: {"legalities.paupercommander": ["legal", "restricted", "banned"]}}
          ],
          minimum_should_match: 1
        }
      }

      # Color identity filter
      if filters[:colors].present?
        colors = Array(filters[:colors])
        if filters[:color_match] == "exact"
          filter_clauses << {terms: {color_identity: colors}}
        else
          colors.each do |color|
            filter_clauses << {term: {color_identity: color}}
          end
        end
      end

      # CMC filters
      if filters[:cmc_min].present? || filters[:cmc_max].present?
        cmc_filter = {range: {cmc: {}}}
        cmc_filter[:range][:cmc][:gte] = filters[:cmc_min].to_f if filters[:cmc_min].present?
        cmc_filter[:range][:cmc][:lte] = filters[:cmc_max].to_f if filters[:cmc_max].present?
        filter_clauses << cmc_filter
      end

      # Type line filter
      if filters[:types].present?
        Array(filters[:types]).each do |card_type|
          filter_clauses << {
            match: {
              type_line: {
                query: card_type,
                operator: "and"
              }
            }
          }
        end
      end

      # Format legality filter
      if filters[:formats].present?
        Array(filters[:formats]).each do |format|
          filter_clauses << {
            term: {
              "legalities.#{format}": "legal"
            }
          }
        end
      end

      # Keyword filter
      if filters[:keywords].present?
        Array(filters[:keywords]).each do |keyword|
          filter_clauses << {term: {keywords: keyword}}
        end
      end

      # Layout filter
      if filters[:layout].present?
        filter_clauses << {term: {layout: filters[:layout]}}
      end

      # Reserved list filter
      if filters[:reserved].present?
        filter_clauses << {term: {reserved: filters[:reserved] == "true"}}
      end

      # Rarity filter
      if filters[:rarities].present?
        filter_clauses << {terms: {rarity: Array(filters[:rarities])}}
      end

      # Power filter
      if filters[:power_min].present? || filters[:power_max].present?
        power_filter = {range: {power: {}}}
        power_filter[:range][:power][:gte] = filters[:power_min].to_i if filters[:power_min].present?
        power_filter[:range][:power][:lte] = filters[:power_max].to_i if filters[:power_max].present?
        filter_clauses << power_filter
      end

      # Toughness filter
      if filters[:toughness_min].present? || filters[:toughness_max].present?
        toughness_filter = {range: {toughness: {}}}
        toughness_filter[:range][:toughness][:gte] = filters[:toughness_min].to_i if filters[:toughness_min].present?
        toughness_filter[:range][:toughness][:lte] = filters[:toughness_max].to_i if filters[:toughness_max].present?
        filter_clauses << toughness_filter
      end

      # Loyalty filter
      if filters[:loyalty_min].present? || filters[:loyalty_max].present?
        loyalty_filter = {range: {loyalty: {}}}
        loyalty_filter[:range][:loyalty][:gte] = filters[:loyalty_min] if filters[:loyalty_min].present?
        loyalty_filter[:range][:loyalty][:lte] = filters[:loyalty_max] if filters[:loyalty_max].present?
        filter_clauses << loyalty_filter
      end

      # EDHREC rank filter
      if filters[:edhrec_rank_min].present? || filters[:edhrec_rank_max].present?
        edhrec_filter = {range: {edhrec_rank: {}}}
        edhrec_filter[:range][:edhrec_rank][:gte] = filters[:edhrec_rank_min].to_i if filters[:edhrec_rank_min].present?
        edhrec_filter[:range][:edhrec_rank][:lte] = filters[:edhrec_rank_max].to_i if filters[:edhrec_rank_max].present?
        filter_clauses << edhrec_filter
      end

      # Penny rank filter
      if filters[:penny_rank_min].present? || filters[:penny_rank_max].present?
        penny_filter = {range: {penny_rank: {}}}
        penny_filter[:range][:penny_rank][:gte] = filters[:penny_rank_min].to_i if filters[:penny_rank_min].present?
        penny_filter[:range][:penny_rank][:lte] = filters[:penny_rank_max].to_i if filters[:penny_rank_max].present?
        filter_clauses << penny_filter
      end

      # Release date filter
      if filters[:released_after].present? || filters[:released_before].present?
        date_filter = {range: {released_at: {}}}
        date_filter[:range][:released_at][:gte] = filters[:released_after] if filters[:released_after].present?
        date_filter[:range][:released_at][:lte] = filters[:released_before] if filters[:released_before].present?
        filter_clauses << date_filter
      end

      # Games/platforms filter
      if filters[:games].present?
        Array(filters[:games]).each do |game|
          filter_clauses << {term: {games: game}}
        end
      end

      # Produced mana filter
      if filters[:produced_mana].present?
        Array(filters[:produced_mana]).each do |mana|
          filter_clauses << {term: {produced_mana: mana}}
        end
      end

      # Finishes filter
      if filters[:finishes].present?
        Array(filters[:finishes]).each do |finish|
          filter_clauses << {term: {finishes: finish}}
        end
      end

      # Artist filter
      if filters[:artists].present?
        filter_clauses << {terms: {artists: Array(filters[:artists])}}
      end

      # Set filter
      if filters[:sets].present?
        filter_clauses << {terms: {sets: Array(filters[:sets])}}
      end

      # Frame filter
      if filters[:frames].present?
        filter_clauses << {terms: {frames: Array(filters[:frames])}}
      end

      # Border color filter
      if filters[:border_colors].present?
        filter_clauses << {terms: {border_colors: Array(filters[:border_colors])}}
      end

      # Frame effects filter
      if filters[:frame_effects].present?
        Array(filters[:frame_effects]).each do |effect|
          filter_clauses << {term: {frame_effects: effect}}
        end
      end

      # Promo types filter
      if filters[:promo_types].present?
        Array(filters[:promo_types]).each do |promo_type|
          filter_clauses << {term: {promo_types: promo_type}}
        end
      end

      # Color indicator filter
      if filters[:color_indicator].present?
        Array(filters[:color_indicator]).each do |color|
          filter_clauses << {term: {color_indicator: color}}
        end
      end

      # Boolean characteristic filters
      filter_clauses << {term: {oversized: filters[:oversized] == "true"}} if filters[:oversized].present?
      filter_clauses << {term: {promo: filters[:promo] == "true"}} if filters[:promo].present?
      filter_clauses << {term: {reprint: filters[:reprint] == "true"}} if filters[:reprint].present?
      filter_clauses << {term: {variation: filters[:variation] == "true"}} if filters[:variation].present?
      filter_clauses << {term: {digital: filters[:digital] == "true"}} if filters[:digital].present?
      filter_clauses << {term: {booster: filters[:booster] == "true"}} if filters[:booster].present?
      filter_clauses << {term: {story_spotlight: filters[:story_spotlight] == "true"}} if filters[:story_spotlight].present?
      filter_clauses << {term: {content_warning: filters[:content_warning] == "true"}} if filters[:content_warning].present?
      filter_clauses << {term: {game_changer: filters[:game_changer] == "true"}} if filters[:game_changer].present?

      # Derived filters for color identity
      if filters[:colorless] == "true"
        filter_clauses << {
          bool: {
            must_not: {exists: {field: "color_identity"}}
          }
        }
      end

      if filters[:mono_color] == "true"
        filter_clauses << {
          script: {
            script: {
              source: "doc['color_identity'].size() == 1"
            }
          }
        }
      end

      if filters[:multicolor] == "true"
        filter_clauses << {
          script: {
            script: {
              source: "doc['color_identity'].size() > 1"
            }
          }
        }
      end

      # Platform availability filters
      if filters[:on_arena] == "true"
        filter_clauses << {exists: {field: "arena_id"}}
      end

      if filters[:on_mtgo] == "true"
        filter_clauses << {exists: {field: "mtgo_id"}}
      end

      # Price filters (USD)
      if filters[:price_usd_min].present? || filters[:price_usd_max].present?
        price_filter = {range: {price_usd: {}}}
        price_filter[:range][:price_usd][:gte] = filters[:price_usd_min].to_f if filters[:price_usd_min].present?
        price_filter[:range][:price_usd][:lte] = filters[:price_usd_max].to_f if filters[:price_usd_max].present?
        filter_clauses << price_filter
      end

      # Price filters (USD Foil)
      if filters[:price_usd_foil_min].present? || filters[:price_usd_foil_max].present?
        price_filter = {range: {price_usd_foil: {}}}
        price_filter[:range][:price_usd_foil][:gte] = filters[:price_usd_foil_min].to_f if filters[:price_usd_foil_min].present?
        price_filter[:range][:price_usd_foil][:lte] = filters[:price_usd_foil_max].to_f if filters[:price_usd_foil_max].present?
        filter_clauses << price_filter
      end

      # Price filters (EUR)
      if filters[:price_eur_min].present? || filters[:price_eur_max].present?
        price_filter = {range: {price_eur: {}}}
        price_filter[:range][:price_eur][:gte] = filters[:price_eur_min].to_f if filters[:price_eur_min].present?
        price_filter[:range][:price_eur][:lte] = filters[:price_eur_max].to_f if filters[:price_eur_max].present?
        filter_clauses << price_filter
      end

      # Price filters (MTGO Tix)
      if filters[:price_tix_min].present? || filters[:price_tix_max].present?
        price_filter = {range: {price_tix: {}}}
        price_filter[:range][:price_tix][:gte] = filters[:price_tix_min].to_f if filters[:price_tix_min].present?
        price_filter[:range][:price_tix][:lte] = filters[:price_tix_max].to_f if filters[:price_tix_max].present?
        filter_clauses << price_filter
      end

      filter_clauses
    end
  end
end
