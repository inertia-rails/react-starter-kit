# frozen_string_literal: true

class EmbeddingBackfillJob < ApplicationJob
  queue_as :default

  # Process cards in smaller batches with delays to avoid rate limits
  BATCH_SIZE = 50 # Smaller batches for embedding generation
  DELAY_BETWEEN_BATCHES = 5 # seconds

  def perform(embedding_run_id, start_id: nil, limit: nil)
    embedding_run = EmbeddingRun.find(embedding_run_id)
    embedding_run.start_processing!

    Rails.logger.info("Starting embedding backfill...")
    Rails.logger.info("Start ID: #{start_id || 'beginning'}, Limit: #{limit || 'all'}")

    begin
      processed = 0
      failed = 0

      # Query cards without embeddings (embeddings_generated_at is NULL)
      scope = Card.joins(:card_legalities)
        .where(card_legalities: {status: ["legal", "restricted", "banned"]})
        .where(embeddings_generated_at: nil)
        .distinct
        .includes(:card_faces, :card_legalities, :card_printings)
        .order(:id)

      scope = scope.where("cards.id >= ?", start_id) if start_id.present?
      scope = scope.limit(limit) if limit.present?

      total_cards = scope.count
      Rails.logger.info("Found #{total_cards} cards to process")

      # Update total count
      embedding_run.update!(total_cards: total_cards)

      scope.find_in_batches(batch_size: BATCH_SIZE) do |batch|
        batch_start = Time.now
        Rails.logger.info("Processing batch of #{batch.size} cards (starting with #{batch.first.name})...")

        begin
          # Generate embeddings for the entire batch at once
          embeddings = Search::EmbeddingService.embed_cards_batch(batch)

          if embeddings.empty?
            Rails.logger.error("Batch embedding generation returned empty results")
            failed += batch.size
          else

            if embeddings.size != batch.size
              Rails.logger.warn("Batch embedding size mismatch: #{embeddings.size} embeddings for #{batch.size} cards")
            end

            # Save embeddings to PostgreSQL and queue OpenSearch reindex
            saved_card_ids = []
            batch.zip(embeddings).each do |card, embedding|
              if embedding.present?
                begin
                  card.update_columns(embedding: embedding, embeddings_generated_at: Time.current)
                  saved_card_ids << card.id
                  processed += 1
                rescue StandardError => e
                  Rails.logger.error("Failed to save embedding for card #{card.id} (#{card.name}): #{e.message}")
                  failed += 1
                end
              else
                Rails.logger.warn("Missing embedding for card #{card.id} (#{card.name})")
                failed += 1
              end
            end

            # Queue OpenSearch reindex jobs for successfully saved cards
            if saved_card_ids.any?
              saved_card_ids.each do |card_id|
                OpenSearchCardUpdateJob.perform_later(card_id, "index")
              end
            end
          end
        rescue StandardError => e
          Rails.logger.error("Failed to process batch: #{e.message}")
          Rails.logger.error(e.backtrace.first(5).join("\n"))
          failed += batch.size
        end

        # Update progress
        embedding_run.update_progress!(processed: processed, failed: failed)

        batch_duration = Time.now - batch_start
        Rails.logger.info("Batch completed in #{batch_duration.round(2)}s. " \
                          "Total: #{processed} processed, #{failed} failed")

        # Sleep between batches to respect rate limits
        # OpenAI free tier: 3 RPM (requests per minute)
        # OpenAI tier 1: 500 RPM
        # We'll be conservative
        sleep(DELAY_BETWEEN_BATCHES)
      end

      Rails.logger.info("Embedding backfill complete!")
      Rails.logger.info("Total: #{processed} processed, #{failed} failed")

      embedding_run.complete!
    rescue StandardError => e
      Rails.logger.error("Embedding backfill job failed: #{e.message}")
      Rails.logger.error(e.backtrace.first(10).join("\n"))
      embedding_run.update!(error_message: e.message)
      embedding_run.fail!
    end
  end
end
