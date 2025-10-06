# frozen_string_literal: true

class ScryfallAllCardsSyncJob < ApplicationJob
  queue_as :default

  def perform
    sync_type = "all_cards"

    # Check if a sync is already in progress
    if ScryfallSync.sync_in_progress?(sync_type)
      Rails.logger.info "Skipping #{sync_type} sync - already in progress"
      return
    end

    Rails.logger.info "Starting scheduled #{sync_type} sync"

    # Create a new sync record
    sync = ScryfallSync.create!(sync_type: sync_type)

    # Queue the sync job
    ScryfallSyncJob.perform_later(sync.id)

    Rails.logger.info "Queued #{sync_type} sync ##{sync.id}"
  end
end
