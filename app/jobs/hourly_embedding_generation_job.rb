# frozen_string_literal: true

class HourlyEmbeddingGenerationJob < ApplicationJob
  queue_as :default

  # Find cards without embeddings and queue individual jobs
  BATCH_SIZE = 100

  def perform
    Rails.logger.info "Starting hourly embedding generation check..."

    # Find cards without embeddings that are legal in at least one format
    cards_needing_embeddings = Card.joins(:card_legalities)
      .where(card_legalities: {status: ["legal", "restricted", "banned"]})
      .where(embeddings_generated_at: nil)
      .distinct
      .limit(BATCH_SIZE)

    count = cards_needing_embeddings.count

    if count.zero?
      Rails.logger.info "No cards need embeddings generated"
      return
    end

    Rails.logger.info "Queueing embedding generation for #{count} cards"

    # Create an embedding run to track progress
    embedding_run = EmbeddingRun.create!(
      total_cards: count,
      processed_cards: 0,
      failed_cards: 0
    )

    # Queue the backfill job for these cards
    EmbeddingBackfillJob.perform_later(
      embedding_run.id,
      start_id: nil,
      limit: BATCH_SIZE
    )

    Rails.logger.info "Queued EmbeddingBackfillJob for run ##{embedding_run.id}"
  end
end
