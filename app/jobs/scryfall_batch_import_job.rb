# frozen_string_literal: true

class ScryfallBatchImportJob < ApplicationJob
  queue_as :low

  def perform(sync_id:, sync_type:, batch_number:, records:)
    @sync = ScryfallSync.find(sync_id)
    @sync_type = sync_type
    @batch_number = batch_number

    Rails.logger.info "Processing batch #{batch_number} with #{records.size} #{sync_type} records"

    case sync_type
    when "oracle_cards"
      process_oracle_cards(records)
    when "default_cards", "all_cards", "unique_artwork"
      process_card_printings(records)
    when "rulings"
      process_rulings(records)
    else
      Rails.logger.error "Unknown sync type: #{sync_type}"
    end

    Rails.logger.info "Completed batch #{batch_number} for #{sync_type}"
  rescue StandardError => e
    Rails.logger.error "Batch #{batch_number} failed for #{sync_type}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    @sync.increment!(:failed_batches)
    @sync.add_failure_log(
      e.message,
      batch_number,
      {
        sync_type: sync_type,
        records_count: records.size,
        error_class: e.class.name,
        backtrace: e.backtrace.first(5)
      }
    )
    raise
  end

  private

  def process_oracle_cards(records)
    mapper = Scryfall::CardMapper.new
    failed_count = 0
    success_count = 0
    card_ids = []

    # Disable OpenSearch callbacks during bulk import for performance
    Card.skip_opensearch_callbacks = true

    records.each do |record|
      card = mapper.import_oracle_card(record)
      card_ids << card.id if card
      success_count += 1
    rescue StandardError => e
      failed_count += 1
      Rails.logger.error "Failed to import oracle card #{record['oracle_id']}: #{e.message}"
      # Log only the first 5 failures per batch to avoid overwhelming the logs
      if failed_count <= 5
        @sync.add_failure_log(
          "Failed to import oracle card: #{e.message}",
          @batch_number,
          {
            oracle_id: record["oracle_id"],
            card_name: record["name"],
            error_class: e.class.name,
            backtrace: e.backtrace.first(3)
          }
        )
      end
    end

    Rails.logger.info "Batch #{@batch_number}: Processed #{success_count} oracle cards, #{failed_count} failures"
  ensure
    # Re-enable callbacks after batch completes
    Card.skip_opensearch_callbacks = false

    # Queue OpenSearch indexing for cards that were imported
    queue_opensearch_jobs(card_ids)
  end

  def process_card_printings(records)
    mapper = Scryfall::CardMapper.new
    failed_count = 0
    success_count = 0
    error_summary = Hash.new(0)
    card_ids = Set.new

    # Disable OpenSearch callbacks during bulk import for performance
    Card.skip_opensearch_callbacks = true
    CardPrinting.skip_opensearch_callbacks = true

    records.each_with_index do |record, index|
      printing = mapper.import_card_printing(record, sync_type: @sync_type)
      card_ids.add(printing.card_id) if printing
      success_count += 1
    rescue ActiveRecord::RecordInvalid => e
      failed_count += 1
      error_summary["validation_error"] += 1
      Rails.logger.error "Validation failed for card printing #{record['id']}: #{e.message}"
      # Log validation errors with full context
      if failed_count <= 5
        @sync.add_failure_log(
          "Validation failed: #{e.message}",
          @batch_number,
          {
            record_index: index,
            card_id: record["id"],
            oracle_id: record["oracle_id"],
            card_name: record["name"],
            set_code: record["set"],
            collector_number: record["collector_number"],
            error_class: e.class.name,
            validation_errors: e.record.errors.full_messages,
            backtrace: e.backtrace.first(3)
          }
        )
      end
    rescue StandardError => e
      failed_count += 1
      error_summary[e.class.name] += 1
      Rails.logger.error "Failed to import card printing #{record['id']}: #{e.message}"
      # Log other errors with context
      if failed_count <= 5
        @sync.add_failure_log(
          "Import failed: #{e.message}",
          @batch_number,
          {
            record_index: index,
            card_id: record["id"],
            oracle_id: record["oracle_id"],
            card_name: record["name"],
            set_code: record["set"],
            collector_number: record["collector_number"],
            error_class: e.class.name,
            backtrace: e.backtrace.first(3)
          }
        )
      end
    end

    # Log batch summary with error breakdown
    summary_msg = "Batch #{@batch_number}: Processed #{success_count} printings, #{failed_count} failures"
    if failed_count > 0
      summary_msg += " (#{error_summary.map { |k, v| "#{k}: #{v}" }.join(', ')})"
    end
    Rails.logger.info summary_msg

    # Add batch summary to sync if there were failures
    if failed_count > 0
      @sync.add_failure_log(
        "Batch summary: #{failed_count} failures",
        @batch_number,
        {
          success_count: success_count,
          failed_count: failed_count,
          error_breakdown: error_summary,
          batch_size: records.size
        }
      )
    end
  ensure
    # Re-enable callbacks after batch completes
    Card.skip_opensearch_callbacks = false
    CardPrinting.skip_opensearch_callbacks = false

    # Queue OpenSearch indexing for cards that were imported
    queue_opensearch_jobs(card_ids.to_a) if card_ids
  end

  def process_rulings(records)
    mapper = Scryfall::RulingMapper.new
    failed_count = 0
    success_count = 0

    records.each do |record|
      mapper.import_ruling(record)
      success_count += 1
    rescue StandardError => e
      failed_count += 1
      Rails.logger.error "Failed to import ruling for #{record['oracle_id']}: #{e.message}"
      # Log only the first 5 failures per batch to avoid overwhelming the logs
      if failed_count <= 5
        @sync.add_failure_log(
          "Failed to import ruling: #{e.message}",
          @batch_number,
          {
            oracle_id: record["oracle_id"],
            source: record["source"],
            error_class: e.class.name
          }
        )
      end
    end

    Rails.logger.info "Batch #{@batch_number}: Processed #{success_count} rulings, #{failed_count} failures"
  end

  def queue_opensearch_jobs(card_ids)
    return if card_ids.blank?

    Rails.logger.info "Batch #{@batch_number}: Queueing OpenSearch indexing for #{card_ids.size} cards"

    card_ids.each do |card_id|
      OpenSearchCardUpdateJob.perform_later(card_id, "index")
    end
  end
end
