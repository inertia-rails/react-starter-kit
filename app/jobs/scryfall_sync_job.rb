# frozen_string_literal: true

require "net/http"
require "fileutils"

class ScryfallSyncJob < ApplicationJob
  queue_as :default

  def perform(sync_id)
    sync = ScryfallSync.find(sync_id)
    return unless sync.may_start?

    # Fetch bulk data info BEFORE starting download
    bulk_data = fetch_bulk_data_info(sync.sync_type)
    unless bulk_data
      sync.fail!("Could not fetch bulk data info for type: #{sync.sync_type}")
      sync.save!
      return
    end

    remote_version = bulk_data.updated_at
    download_uri = bulk_data.download_uri
    file_size = bulk_data.size

    # Check if we already have this version BEFORE starting
    latest_sync = ScryfallSync.latest_for_type(sync.sync_type)
    if latest_sync && !latest_sync.needs_update?(remote_version)
      sync.skip!("Already have the latest version: #{remote_version}")
      sync.save!
      return
    end

    # Now start the download
    sync.start!
    sync.save!

    # Check if cancelled before download
    return if sync.reload.cancelled?

    file_path = download_file(sync, download_uri, remote_version)

    cleanup_old_files(sync.sync_type, sync.id)

    sync.version = remote_version
    sync.download_uri = download_uri
    sync.complete!(file_path, file_size)
    sync.save!

    Rails.logger.info "Successfully synced #{sync.sync_type} version #{remote_version}"

    # Queue the processing job
    ScryfallProcessingJob.perform_later(sync.id)
    Rails.logger.info "Queued processing job for #{sync.sync_type} sync #{sync.id}"
  rescue StandardError => e
    Rails.logger.error "ScryfallSyncJob failed for sync #{sync_id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    if sync && sync.may_fail?
      sync.fail!(e.message)
      sync.save!
    end
  end

  private

  def fetch_bulk_data_info(sync_type)
    Scryfall::BulkData.find_by_type(sync_type)
  rescue StandardError => e
    Rails.logger.error "Failed to fetch bulk data info: #{e.message}"
    nil
  end

  def download_file(sync, url, version)
    ensure_storage_directory(sync.sync_type)

    uri = URI(url)
    filename = File.basename(uri.path)
    file_path = Rails.root.join("storage", "scryfall", sync.sync_type, filename)

    Rails.logger.info "Downloading #{sync.sync_type} from #{url} to #{file_path}"

    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
      request = Net::HTTP::Get.new(uri)

      http.request(request) do |response|
        unless response.is_a?(Net::HTTPSuccess)
          raise "HTTP Error: #{response.code} #{response.message}"
        end

        total_size = response["content-length"].to_i
        downloaded = 0

        File.open(file_path, "wb") do |file|
          response.read_body do |chunk|
            # Check if sync was cancelled during download
            if sync.reload.cancelled?
              file.close
              File.delete(file_path) if File.exist?(file_path)
              Rails.logger.info "Download cancelled for #{sync.sync_type}"
              raise "Download cancelled"
            end

            file.write(chunk)
            downloaded += chunk.bytesize

            if total_size > 0
              progress = (downloaded.to_f / total_size * 100).round(2)
              Rails.logger.info "Downloading #{sync.sync_type}: #{progress}% (#{downloaded}/#{total_size} bytes)"
            end
          end
        end
      end
    end

    Rails.logger.info "Successfully downloaded #{sync.sync_type} to #{file_path}"
    file_path.to_s
  end

  def ensure_storage_directory(sync_type)
    dir = Rails.root.join("storage", "scryfall", sync_type)
    FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
  end

  def cleanup_old_files(sync_type, current_sync_id)
    old_syncs = ScryfallSync.by_type(sync_type)
                            .completed
                            .where.not(id: current_sync_id)
                            .where.not(file_path: nil)

    old_syncs.each do |old_sync|
      old_sync.cleanup_old_files!
    end
  end
end
