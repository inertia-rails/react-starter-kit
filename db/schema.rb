# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_10_06_022004) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"
  enable_extension "pgcrypto"

  create_table "card_faces", force: :cascade do |t|
    t.uuid "card_id", null: false
    t.integer "face_index", null: false
    t.string "name", null: false
    t.string "mana_cost"
    t.string "type_line"
    t.text "oracle_text"
    t.jsonb "colors", default: []
    t.jsonb "color_indicator"
    t.string "power"
    t.string "toughness"
    t.string "loyalty"
    t.string "defense"
    t.text "flavor_text"
    t.string "artist"
    t.string "illustration_id"
    t.jsonb "image_uris", default: {}
    t.string "flavor_name"
    t.string "printed_name"
    t.text "printed_text"
    t.string "printed_type_line"
    t.string "watermark"
    t.string "layout"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "artist_ids", default: [], comment: "Array of artist IDs"
    t.index ["card_id", "face_index"], name: "index_card_faces_on_card_id_and_face_index", unique: true
    t.index ["card_id"], name: "index_card_faces_on_card_id"
    t.index ["name"], name: "index_card_faces_on_name"
  end

  create_table "card_legalities", force: :cascade do |t|
    t.uuid "card_id", null: false
    t.string "format", null: false
    t.string "status", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["card_id", "format"], name: "index_card_legalities_on_card_id_and_format", unique: true
    t.index ["card_id"], name: "index_card_legalities_on_card_id"
    t.index ["format", "status"], name: "index_card_legalities_on_format_and_status"
  end

  create_table "card_printings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "card_id", null: false
    t.uuid "card_set_id", null: false
    t.string "collector_number", null: false
    t.string "rarity", null: false
    t.string "watermark"
    t.string "printed_name"
    t.text "printed_text"
    t.string "printed_type_line"
    t.string "artist"
    t.string "illustration_id"
    t.string "border_color", null: false
    t.string "frame"
    t.string "security_stamp"
    t.boolean "full_art", default: false
    t.boolean "textless", default: false
    t.boolean "booster", default: true
    t.boolean "story_spotlight", default: false
    t.boolean "promo", default: false
    t.boolean "reprint", default: false
    t.jsonb "prices", default: {}
    t.jsonb "image_uris", default: {}
    t.jsonb "preview"
    t.jsonb "promo_types", default: []
    t.jsonb "frame_effects", default: []
    t.jsonb "finishes", default: []
    t.jsonb "multiverse_ids", default: []
    t.jsonb "attraction_lights", default: []
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "scryfall_id", comment: "Scryfall's unique printing ID"
    t.uuid "card_back_id", comment: "ID of the card back for this printing"
    t.boolean "content_warning", default: false
    t.uuid "variation_of"
    t.jsonb "purchase_uris", default: {}, comment: "Purchase links for this printing"
    t.jsonb "related_uris", default: {}, comment: "Related URIs for this printing"
    t.jsonb "artist_ids", default: [], comment: "Array of artist IDs"
    t.string "lang", default: "en", null: false
    t.boolean "is_default", default: false, null: false
    t.index ["artist"], name: "index_card_printings_on_artist"
    t.index ["card_back_id"], name: "index_card_printings_on_card_back_id"
    t.index ["card_id", "card_set_id", "collector_number"], name: "idx_printings_unique", unique: true
    t.index ["card_id"], name: "index_card_printings_on_card_id"
    t.index ["card_set_id"], name: "index_card_printings_on_card_set_id"
    t.index ["is_default"], name: "index_card_printings_on_is_default"
    t.index ["lang"], name: "index_card_printings_on_lang"
    t.index ["prices"], name: "index_card_printings_on_prices", using: :gin
    t.index ["rarity"], name: "index_card_printings_on_rarity"
    t.index ["scryfall_id"], name: "index_card_printings_on_scryfall_id", unique: true
  end

  create_table "card_rulings", force: :cascade do |t|
    t.uuid "oracle_id", null: false
    t.string "source", null: false
    t.date "published_at", null: false
    t.text "comment", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["oracle_id"], name: "index_card_rulings_on_oracle_id"
    t.index ["published_at"], name: "index_card_rulings_on_published_at"
  end

  create_table "card_sets", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "code", null: false
    t.string "name", null: false
    t.string "set_type", null: false
    t.date "released_at"
    t.string "block"
    t.string "block_code"
    t.integer "card_count"
    t.boolean "digital", default: false
    t.boolean "foil_only", default: false
    t.boolean "nonfoil_only", default: false
    t.string "icon_svg_uri"
    t.string "scryfall_uri"
    t.string "uri"
    t.string "search_uri"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "parent_set_code"
    t.integer "tcgplayer_id"
    t.index ["code"], name: "index_card_sets_on_code", unique: true
    t.index ["released_at"], name: "index_card_sets_on_released_at"
    t.index ["set_type"], name: "index_card_sets_on_set_type"
  end

  create_table "cards", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "oracle_id", null: false
    t.string "name", null: false
    t.string "lang", default: "en"
    t.date "released_at"
    t.string "uri"
    t.string "scryfall_uri"
    t.string "layout", null: false
    t.boolean "highres_image", default: true
    t.string "image_status", null: false
    t.float "cmc", null: false
    t.string "type_line", null: false
    t.text "oracle_text"
    t.string "mana_cost"
    t.string "power"
    t.string "toughness"
    t.string "loyalty"
    t.string "life_modifier"
    t.string "hand_modifier"
    t.jsonb "colors", default: []
    t.jsonb "color_identity", default: []
    t.jsonb "color_indicator", default: []
    t.jsonb "produced_mana", default: []
    t.jsonb "keywords", default: []
    t.jsonb "games", default: []
    t.boolean "reserved", default: false
    t.boolean "foil", default: true
    t.boolean "nonfoil", default: true
    t.boolean "oversized", default: false
    t.boolean "promo", default: false
    t.boolean "reprint", default: false
    t.boolean "variation", default: false
    t.boolean "digital", default: false
    t.boolean "full_art", default: false
    t.boolean "textless", default: false
    t.boolean "booster", default: true
    t.boolean "story_spotlight", default: false
    t.integer "edhrec_rank"
    t.integer "penny_rank"
    t.integer "arena_id"
    t.integer "mtgo_id"
    t.integer "mtgo_foil_id"
    t.integer "tcgplayer_id"
    t.integer "tcgplayer_etched_id"
    t.integer "cardmarket_id"
    t.string "prints_search_uri"
    t.string "rulings_uri"
    t.string "scryfall_set_uri"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "scryfall_id", comment: "Scryfall's unique card ID"
    t.uuid "card_back_id", comment: "ID of the card back for double-faced cards"
    t.boolean "game_changer", default: false, comment: "Whether this card is a game changer"
    t.boolean "content_warning", default: false, comment: "Whether this card has content warnings"
    t.uuid "variation_of", comment: "ID of the card this is a variation of"
    t.jsonb "purchase_uris", default: {}, comment: "Purchase links (aggregated from printings)"
    t.jsonb "related_uris", default: {}, comment: "Related URIs (aggregated)"
    t.datetime "embeddings_generated_at"
    t.index ["card_back_id"], name: "index_cards_on_card_back_id"
    t.index ["cmc"], name: "index_cards_on_cmc"
    t.index ["color_identity"], name: "index_cards_on_color_identity", using: :gin
    t.index ["colors"], name: "index_cards_on_colors", using: :gin
    t.index ["keywords"], name: "index_cards_on_keywords", using: :gin
    t.index ["name"], name: "index_cards_on_name"
    t.index ["oracle_id"], name: "index_cards_on_oracle_id", unique: true
    t.index ["oracle_text"], name: "index_cards_on_oracle_text", opclass: :gin_trgm_ops, using: :gin
    t.index ["released_at"], name: "index_cards_on_released_at"
    t.index ["scryfall_id"], name: "index_cards_on_scryfall_id", unique: true
    t.index ["type_line"], name: "index_cards_on_type_line"
    t.index ["variation_of"], name: "index_cards_on_variation_of"
  end

  create_table "embedding_runs", force: :cascade do |t|
    t.string "status"
    t.integer "total_cards"
    t.integer "processed_cards"
    t.integer "failed_cards"
    t.integer "batch_size"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "open_search_syncs", force: :cascade do |t|
    t.string "status", default: "pending", null: false
    t.integer "total_cards", default: 0
    t.integer "indexed_cards", default: 0
    t.integer "failed_cards", default: 0
    t.datetime "started_at"
    t.datetime "completed_at"
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_open_search_syncs_on_created_at"
    t.index ["status"], name: "index_open_search_syncs_on_status"
  end

  create_table "opensearch_migrations", force: :cascade do |t|
    t.string "version", null: false
    t.string "name", null: false
    t.datetime "applied_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["version"], name: "index_opensearch_migrations_on_version", unique: true
  end

  create_table "related_cards", force: :cascade do |t|
    t.uuid "card_id", null: false
    t.uuid "related_card_id", null: false
    t.string "component", null: false
    t.string "name", null: false
    t.string "type_line", null: false
    t.string "uri"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "scryfall_id", comment: "Scryfall's ID for the related card"
    t.index ["card_id", "related_card_id", "component"], name: "idx_related_unique", unique: true
    t.index ["card_id"], name: "index_related_cards_on_card_id"
    t.index ["related_card_id"], name: "index_related_cards_on_related_card_id"
    t.index ["scryfall_id"], name: "index_related_cards_on_scryfall_id"
  end

  create_table "scryfall_syncs", force: :cascade do |t|
    t.string "sync_type", null: false
    t.string "status", default: "pending", null: false
    t.string "version"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.text "error_message"
    t.bigint "file_size"
    t.string "download_uri"
    t.string "file_path"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "cancelled_at"
    t.integer "total_records"
    t.integer "processed_records", default: 0
    t.integer "failed_batches", default: 0
    t.string "processing_status"
    t.datetime "processing_started_at"
    t.datetime "processing_completed_at"
    t.integer "last_processed_batch"
    t.integer "batch_size", default: 500
    t.jsonb "failure_logs", default: []
    t.jsonb "error_summary", default: {}
    t.integer "invalid_uuid_count", default: 0
    t.integer "warning_count", default: 0
    t.index ["failure_logs"], name: "index_scryfall_syncs_on_failure_logs", using: :gin
    t.index ["invalid_uuid_count"], name: "index_scryfall_syncs_on_invalid_uuid_count"
    t.index ["processing_status"], name: "index_scryfall_syncs_on_processing_status"
    t.index ["status"], name: "index_scryfall_syncs_on_status"
    t.index ["sync_type", "version"], name: "index_scryfall_syncs_on_sync_type_and_version", unique: true
    t.index ["sync_type"], name: "index_scryfall_syncs_on_sync_type"
    t.index ["warning_count"], name: "index_scryfall_syncs_on_warning_count"
  end

  create_table "search_evals", force: :cascade do |t|
    t.string "status"
    t.string "eval_type"
    t.integer "total_queries"
    t.integer "completed_queries"
    t.integer "failed_queries"
    t.decimal "avg_precision"
    t.decimal "avg_recall"
    t.decimal "avg_mrr"
    t.decimal "avg_ndcg"
    t.boolean "use_llm_judge"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.text "error_message"
    t.jsonb "results"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.boolean "verified", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "admin", default: false, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "card_faces", "cards"
  add_foreign_key "card_legalities", "cards"
  add_foreign_key "card_printings", "card_sets"
  add_foreign_key "card_printings", "cards"
  add_foreign_key "related_cards", "cards"
  add_foreign_key "sessions", "users"
end
