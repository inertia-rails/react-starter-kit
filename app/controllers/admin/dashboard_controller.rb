# frozen_string_literal: true

class Admin::DashboardController < InertiaController
  before_action :require_admin

  def index
    # Use approximate counts for large tables (fast) and exact counts for small tables
    # Cache for 5 minutes to reduce database load
    @users_count = User.count
    @cards_count = approximate_count(Card)
    @card_sets_count = CardSet.count
    @card_printings_count = approximate_count(CardPrinting)
    @card_faces_count = approximate_count(CardFace)
    @card_rulings_count = approximate_count(CardRuling)
    @card_legalities_count = approximate_count(CardLegality)
    @related_cards_count = approximate_count(RelatedCard)
    @scryfall_syncs_count = ScryfallSync.count
    @open_search_syncs_count = OpenSearchSync.count
    @search_evals_count = SearchEval.count
    @embedding_runs_count = EmbeddingRun.count
    @recent_users = User.order(created_at: :desc).limit(5)

    render inertia: "admin/dashboard", props: {
      stats: {
        users_count: @users_count,
        cards_count: @cards_count,
        card_sets_count: @card_sets_count,
        card_printings_count: @card_printings_count,
        card_faces_count: @card_faces_count,
        card_rulings_count: @card_rulings_count,
        card_legalities_count: @card_legalities_count,
        related_cards_count: @related_cards_count,
        scryfall_syncs_count: @scryfall_syncs_count,
        open_search_syncs_count: @open_search_syncs_count,
        search_evals_count: @search_evals_count,
        embedding_runs_count: @embedding_runs_count
      },
      recent_users: @recent_users.map { |user|
        {
          id: user.id,
          name: user.name,
          email: user.email,
          created_at: user.created_at.strftime("%B %d, %Y"),
          verified: user.verified,
          admin: user.admin
        }
      },
      sync_status: Rails.cache.fetch("admin_dashboard_sync_status", expires_in: 2.minutes) { fetch_sync_status },
      open_search_sync_status: Rails.cache.fetch("admin_dashboard_opensearch_status", expires_in: 2.minutes) { open_search_sync_status_data },
      search_eval_status: Rails.cache.fetch("admin_dashboard_search_eval_status", expires_in: 2.minutes) { search_eval_status_data },
      embedding_run_status: Rails.cache.fetch("admin_dashboard_embedding_status", expires_in: 2.minutes) { embedding_run_status_data }
    }
  end

  private

  def approximate_count(model)
    # Use PostgreSQL's pg_class statistics for fast approximate counts
    # Falls back to exact count if table stats unavailable
    Rails.cache.fetch("#{model.table_name}_count", expires_in: 5.minutes) do
      result = ActiveRecord::Base.connection.execute(<<~SQL)
        SELECT reltuples::bigint AS estimate
        FROM pg_class
        WHERE relname = '#{model.table_name}'
      SQL

      estimate = result.first["estimate"].to_i
      # If estimate is 0 or seems stale, fall back to exact count
      estimate > 0 ? estimate : model.count
    end
  end

  def fetch_sync_status
    # Batch query: Get most recent sync for each type in a single query
    recent_syncs = ScryfallSync
      .select("DISTINCT ON (sync_type) *")
      .where(sync_type: ScryfallSync::VALID_SYNC_TYPES)
      .order(:sync_type, created_at: :desc)
      .index_by(&:sync_type)

    # Build result for all sync types
    ScryfallSync::VALID_SYNC_TYPES.map do |sync_type|
      sync = recent_syncs[sync_type]
      if sync
        {
          sync_type: sync.sync_type,
          status: sync.status,
          version: sync.version,
          completed_at: sync.completed_at&.strftime("%B %d, %Y %H:%M"),
          processing_status: sync.processing_status,
          total_records: sync.total_records,
          processed_records: sync.processed_records
        }
      else
        {
          sync_type: sync_type,
          status: "never_synced",
          version: nil,
          completed_at: nil,
          processing_status: nil,
          total_records: nil,
          processed_records: nil
        }
      end
    end
  end

  def open_search_sync_status_data
    recent_sync = OpenSearchSync.recent.first
    index_stats = Rails.cache.fetch("opensearch_index_stats", expires_in: 5.minutes) do
      Search::CardIndexer.new.index_stats
    end

    {
      recent_sync: recent_sync ? {
        id: recent_sync.id,
        status: recent_sync.status,
        total_cards: recent_sync.total_cards,
        indexed_cards: recent_sync.indexed_cards,
        failed_cards: recent_sync.failed_cards,
        progress_percentage: recent_sync.progress_percentage,
        started_at: recent_sync.started_at&.strftime("%B %d, %Y %H:%M"),
        completed_at: recent_sync.completed_at&.strftime("%B %d, %Y %H:%M"),
        duration_formatted: recent_sync.duration_formatted,
        error_message: recent_sync.error_message
      } : nil,
      index_stats: index_stats
    }
  end

  def search_eval_status_data
    recent_eval = SearchEval.recent.first

    {
      recent_eval: recent_eval ? {
        id: recent_eval.id,
        status: recent_eval.status,
        eval_type: recent_eval.eval_type,
        total_queries: recent_eval.total_queries,
        completed_queries: recent_eval.completed_queries,
        failed_queries: recent_eval.failed_queries,
        progress_percentage: recent_eval.progress_percentage,
        avg_precision: recent_eval.avg_precision,
        avg_recall: recent_eval.avg_recall,
        avg_mrr: recent_eval.avg_mrr,
        avg_ndcg: recent_eval.avg_ndcg,
        use_llm_judge: recent_eval.use_llm_judge,
        started_at: recent_eval.started_at&.strftime("%B %d, %Y %H:%M"),
        completed_at: recent_eval.completed_at&.strftime("%B %d, %Y %H:%M"),
        duration_formatted: recent_eval.duration_formatted,
        error_message: recent_eval.error_message
      } : nil
    }
  end

  def embedding_run_status_data
    recent_run = EmbeddingRun.recent.first

    # Calculate what percentage of cards have embeddings
    total_cards = @cards_count || approximate_count(Card)
    cards_with_embeddings = Rails.cache.fetch("cards_with_embeddings_count", expires_in: 5.minutes) do
      Card.where.not(embeddings_generated_at: nil).count
    end
    embedding_coverage_percentage = total_cards > 0 ? (cards_with_embeddings.to_f / total_cards * 100).round(1) : 0

    {
      recent_run: recent_run ? {
        id: recent_run.id,
        status: recent_run.status,
        total_cards: recent_run.total_cards,
        processed_cards: recent_run.processed_cards,
        failed_cards: recent_run.failed_cards,
        batch_size: recent_run.batch_size,
        progress_percentage: recent_run.progress_percentage,
        started_at: recent_run.started_at&.strftime("%B %d, %Y %H:%M"),
        completed_at: recent_run.completed_at&.strftime("%B %d, %Y %H:%M"),
        duration_formatted: recent_run.duration_formatted,
        error_message: recent_run.error_message
      } : nil,
      embedding_coverage: {
        total_cards: total_cards,
        cards_with_embeddings: cards_with_embeddings,
        percentage: embedding_coverage_percentage
      }
    }
  end
end
