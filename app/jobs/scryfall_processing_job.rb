# frozen_string_literal: true

require "json"

class ScryfallProcessingJob < ApplicationJob
  queue_as :default

  def perform(sync_id)
    @sync = ScryfallSync.find(sync_id)
    unless @sync.completed? && @sync.file_path.present?
      raise "Unable to process sync #{sync_id}: download not completed or missing file"
    end

    Rails.logger.info "Starting processing for #{@sync.sync_type} sync #{sync_id}"

    # Count total records first
    total = count_records(@sync.file_path)
    @sync.update!(total_records: total, processing_status: "queued")

    # Start processing
    @sync.start_processing!

    # Use smaller batch size for all_cards to avoid memory issues
    batch_size = @sync.sync_type == "all_cards" ? 100 : (@sync.batch_size || 250)
    process_file_in_batches(@sync.file_path, batch_size)

    # Mark processing as completed
    @sync.complete_processing!

    Rails.logger.info "Completed processing for #{@sync.sync_type} sync #{sync_id}"
  rescue StandardError => e
    Rails.logger.error "ScryfallProcessingJob failed for sync #{sync_id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    @sync&.fail_processing!(e.message)
  end

  private

  def count_records(file_path)
    count = 0
    File.open(file_path, "r") do |file|
      file.each_line do |line|
        line.strip!
        # Skip empty lines and array brackets
        next if line.empty? || line == "[" || line == "]"
        # Count actual JSON objects (lines ending with } or },)
        count += 1 if line.end_with?("}") || line.end_with?("},")
      end
    end
    count
  end

  def process_file_in_batches(file_path, batch_size)
    batch = []
    batch_number = 0
    processed = 0

    File.open(file_path, "r") do |file|
      file.each_line do |line|
        line.strip!

        # Skip empty lines and array brackets
        next if line.empty? || line == "[" || line == "]"

        # Remove trailing comma if present
        line = line.chomp(",")

        begin
          # Parse the JSON object
          record = JSON.parse(line)
          batch << record

          # Process batch when it reaches the batch size
          if batch.size >= batch_size
            batch_number += 1
            process_batch(batch, batch_number)
            processed += batch.size

            # Update progress
            @sync.update_processing_progress!(processed, batch_number)

            # Clear batch
            batch = []
          end
        rescue JSON::ParserError => e
          Rails.logger.warn "Skipping invalid JSON: #{e.message}"
        end
      end
    end

    # Process any remaining records
    if batch.any?
      batch_number += 1
      process_batch(batch, batch_number)
      processed += batch.size
      @sync.update_processing_progress!(processed, batch_number)
    end
  end

  def process_batch(batch, batch_number)
    Rails.logger.info "Queueing batch #{batch_number} with #{batch.size} records for #{@sync.sync_type}"

    # Queue the batch import job
    ScryfallBatchImportJob.perform_later(
      sync_id: @sync.id,
      sync_type: @sync.sync_type,
      batch_number: batch_number,
      records: batch
    )

    # For large datasets, throttle job creation to avoid overwhelming the queue
    if @sync.sync_type == "all_cards" && batch_number % 10 == 0
      # Check queue depth and wait if too many jobs are pending
      queue = Sidekiq::Queue.new("low")
      pending_count = queue.size

      if pending_count > 50
        Rails.logger.info "Throttling: #{pending_count} jobs pending, waiting..."
        sleep(2)
      end
    end
  end
end
