# frozen_string_literal: true

module Search
  class CardSearch < Base
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
      # Determine which search mode to use
      mode = determine_search_mode(query, search_mode)

      search_body = case mode
      when "semantic"
        build_semantic_search_query(query, filters)
      when "hybrid"
        build_hybrid_search_query(query, filters)
      else
        build_search_query(query, filters)
      end

      search_body[:from] = (page - 1) * per_page
      search_body[:size] = per_page

      response = client.search(
        index: index_name,
        body: search_body
      )

      format_search_results(response, page, per_page)
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

    def build_search_query(query, filters)
      query_clauses = []
      filter_clauses = []

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

      # Color identity filter
      if filters[:colors].present?
        colors = Array(filters[:colors])
        if filters[:color_match] == "exact"
          filter_clauses << {terms: {color_identity: colors}}
        else
          # Default: cards that include all specified colors
          colors.each do |color|
            filter_clauses << {term: {color_identity: color}}
          end
        end
      end

      # CMC (mana value) filters
      if filters[:cmc_min].present? || filters[:cmc_max].present?
        cmc_filter = {range: {cmc: {}}}
        cmc_filter[:range][:cmc][:gte] = filters[:cmc_min].to_f if filters[:cmc_min].present?
        cmc_filter[:range][:cmc][:lte] = filters[:cmc_max].to_f if filters[:cmc_max].present?
        filter_clauses << cmc_filter
      end

      # Type line filter (partial match)
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

      # EDHREC rank filter (lower is better/more popular)
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

      # Build the final query
      {
        query: {
          bool: {
            must: query_clauses.any? ? query_clauses : [{match_all: {}}],
            filter: filter_clauses
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

      # Use k-NN with post-filtering for better semantic ranking
      # Get more candidates (k=200) and then filter to allow semantic relevance to dominate
      search_query = {
        size: 20, # Will be overridden by caller
        query: {
          knn: {
            embedding: {
              vector: query_embedding,
              k: 200 # Increased k to get more candidates before filtering
            }
          }
        },
        _source: {excludes: ["embedding"]}
      }

      # Apply filters as post-filter if any exist
      # This preserves semantic ranking while still filtering results
      if filter_clauses.any?
        search_query[:post_filter] = {
          bool: {
            filter: filter_clauses
          }
        }
      end

      search_query
    end

    # Build a hybrid search query combining k-NN and keyword search
    def build_hybrid_search_query(query, filters)
      query_embedding = EmbeddingService.embed(query)

      # Fall back to keyword search if embedding fails
      return build_search_query(query, filters) if query_embedding.blank?

      filter_clauses = build_filter_clauses(filters)

      # Hybrid approach: Use script_score to combine k-NN similarity with keyword relevance
      # This properly combines both signals into a single score
      {
        query: {
          script_score: {
            query: {
              bool: {
                should: [
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
                minimum_should_match: 0 # Allow either keyword or semantic to match
              }
            },
            script: {
              source: """
                double keywordScore = Math.max(_score, 0.1);
                double vectorScore = cosineSimilarity(params.query_vector, doc['embedding']) + 1.0;
                return (vectorScore * 3.0) + (keywordScore * 1.0);
              """,
              params: {
                query_vector: query_embedding
              }
            }
          }
        },
        _source: {excludes: ["embedding"]}
      }
    end

    # Extract filter building logic for reuse
    def build_filter_clauses(filters)
      filter_clauses = []

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
