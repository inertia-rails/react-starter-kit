# frozen_string_literal: true

class ScryfallSync < ApplicationRecord
  include AASM

  VALID_SYNC_TYPES = %w[oracle_cards unique_artwork default_cards all_cards rulings].freeze

  validates :sync_type, presence: true, inclusion: {in: VALID_SYNC_TYPES}
  validates :version, uniqueness: {scope: :sync_type}, allow_nil: true

  scope :by_type, ->(type) { where(sync_type: type) }
  scope :pending_or_downloading, -> { where(status: %w[pending downloading]) }
  scope :completed, -> { where(status: "completed") }
  scope :processing, -> { where(processing_status: %w[processing queued]) }
  scope :completed_processing, -> { where(processing_status: "completed") }

  # AASM state machine configuration for download status
  aasm column: :status do
    state :pending, initial: true
    state :downloading
    state :completed
    state :failed
    state :cancelled
    state :skipped

    event :start do
      transitions from: :pending, to: :downloading do
        after do
          self.started_at = Time.current
        end
      end
    end

    event :complete do
      transitions from: :downloading, to: :completed do
        after do |file_path, file_size|
          self.completed_at = Time.current
          self.file_path = file_path
          self.file_size = file_size
          self.error_message = nil
        end
      end
    end

    event :fail do
      transitions from: [:pending, :downloading], to: :failed do
        after do |error_message|
          self.completed_at = Time.current
          self.error_message = error_message
        end
      end
    end

    event :skip do
      transitions from: :pending, to: :skipped do
        after do |message|
          self.completed_at = Time.current
          self.error_message = message
        end
      end
    end

    event :cancel do
      transitions from: [:pending, :downloading], to: :cancelled do
        guard do
          destroy_associated_jobs
        end
        after do
          self.cancelled_at = Time.current
        end
      end
    end
  end

  def self.latest_for_type(type)
    by_type(type).completed.order(created_at: :desc).first
  end

  def self.sync_in_progress?(type)
    by_type(type).pending_or_downloading.exists?
  end

  def cancelable?
    pending? || downloading?
  end

  def duration
    return nil unless started_at

    ending = completed_at || Time.current
    ending - started_at
  end

  def needs_update?(remote_version)
    return true if version.blank?

    version != remote_version
  end

  def storage_directory
    Rails.root.join("storage", "scryfall", sync_type)
  end

  def cleanup_old_files!
    return unless file_path.present? && File.exist?(file_path)

    File.delete(file_path)
    Rails.logger.info "Deleted old file: #{file_path}"
  rescue StandardError => e
    Rails.logger.error "Failed to delete old file #{file_path}: #{e.message}"
  end

  # Processing status methods
  def processing?
    processing_status == "processing"
  end

  def processing_queued?
    processing_status == "queued"
  end

  def processing_completed?
    processing_status == "completed"
  end

  def processing_failed?
    processing_status == "failed"
  end

  def processing_progress_percentage
    return 0 unless total_records && total_records > 0
    ((processed_records.to_f / total_records) * 100).round(2)
  end

  def add_failure_log(error_message, batch_number = nil, context = {})
    log_entry = {
      timestamp: Time.current.iso8601,
      error: error_message,
      batch_number: batch_number,
      context: context
    }

    # Keep only the last 100 failure logs to prevent unbounded growth
    self.failure_logs ||= []
    self.failure_logs << log_entry
    self.failure_logs = failure_logs.last(100)

    # Update error summary
    update_error_summary(error_message, context)

    save
  end

  def update_error_summary(error_message, context = {})
    self.error_summary ||= {}

    # Track error types
    error_type = context[:error_class] || "unknown"
    self.error_summary[error_type] ||= 0
    self.error_summary[error_type] += 1

    # Track specific error patterns
    if error_message.include?("UUID")
      self.invalid_uuid_count ||= 0
      self.invalid_uuid_count += 1
    end

    # Track validation errors separately
    if context[:validation_errors].present?
      self.error_summary["validation_errors"] ||= {}
      context[:validation_errors].each do |ve|
        self.error_summary["validation_errors"][ve] ||= 0
        self.error_summary["validation_errors"][ve] += 1
      end
    end
  end

  def add_warning(warning_message, context = {})
    self.warning_count ||= 0
    self.warning_count += 1

    Rails.logger.warn "ScryfallSync ##{id}: #{warning_message} - #{context.inspect}"
  end

  def clear_failure_logs
    update(failure_logs: [])
  end

  def job_progress
    # With Sidekiq, we don't have per-sync job tracking like Solid Queue
    # Instead, we track progress via processed_records/total_records
    # Return estimated job progress based on batch processing
    return {total: 0, completed: 0, failed: 0, pending: 0, percentage: 0} unless processing? || processing_completed?

    # Estimate jobs based on records and batch size (default 250 records per job)
    batch_size = self.batch_size || 250
    total_jobs = total_records ? (total_records.to_f / batch_size).ceil : 0
    completed_jobs = processed_records ? (processed_records.to_f / batch_size).floor : 0
    failed_jobs = failed_batches || 0
    pending_jobs = [total_jobs - completed_jobs - failed_jobs, 0].max

    {
      total: total_jobs,
      completed: completed_jobs,
      failed: failed_jobs,
      pending: pending_jobs,
      percentage: total_jobs > 0 ? ((completed_jobs.to_f / total_jobs) * 100).round(2) : 0
    }
  end

  def calculate_job_progress
    # This method is no longer used with Sidekiq
    # Job progress is calculated directly in job_progress method above
    job_progress
  end

  def estimated_completion_time
    return nil unless processing_started_at && processed_records > 0 && total_records

    elapsed = Time.current - processing_started_at
    rate = processed_records.to_f / elapsed
    remaining = total_records - processed_records

    return nil if rate == 0

    seconds_remaining = remaining / rate
    processing_started_at + elapsed + seconds_remaining.seconds
  end

  def update_processing_progress!(processed_count, batch_number = nil)
    updates = {
      processed_records: processed_count,
      processing_status: "processing"
    }
    updates[:last_processed_batch] = batch_number if batch_number
    update!(updates)
  end

  def start_processing!
    update!(
      processing_status: "processing",
      processing_started_at: Time.current,
      processed_records: 0,
      failed_batches: 0
    )
  end

  def complete_processing!
    update!(
      processing_status: "completed",
      processing_completed_at: Time.current
    )
  end

  def fail_processing!(error_message)
    update!(
      processing_status: "failed",
      processing_completed_at: Time.current,
      error_message: error_message
    )
  end

  def associated_jobs
    # Sidekiq doesn't provide direct job querying like Solid Queue
    # Jobs are tracked via the processing_status and processed_records fields
    # Return an empty array as this method is no longer needed with Sidekiq
    []
  end

  def active_jobs
    # Sidekiq workers can be inspected via Sidekiq::Workers
    # but we'll rely on the processing_status field instead
    []
  end

  def processing_jobs
    # With Sidekiq, job progress is tracked via the sync record itself
    # rather than querying the job queue
    []
  end

  private

  def destroy_associated_jobs
    # With Sidekiq, we cannot directly cancel jobs from the queue
    # We'll mark the sync as cancelled and jobs should check the status
    # before processing
    Rails.logger.info "Marking sync #{id} as cancelled (Sidekiq jobs will check status)"
    true
  rescue StandardError => e
    Rails.logger.error "Failed to cancel sync #{id}: #{e.message}"
    false
  end
end
