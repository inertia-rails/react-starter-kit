# frozen_string_literal: true

module Search
  class Migration
    attr_reader :indexer, :version, :name

    def initialize(version:, name:)
      @indexer = CardIndexer.new
      @version = version
      @name = name
    end

    # DSL method: Add a field to the index mapping
    def add_field(field_name, mapping)
      return false unless indexer.send(:index_exists?)

      indexer.send(:client).indices.put_mapping(
        index: indexer.send(:index_name),
        body: {
          properties: {
            field_name => mapping
          }
        }
      )
      Rails.logger.info("OpenSearch Migration: Added field '#{field_name}' to index")
      true
    rescue StandardError => e
      Rails.logger.error("OpenSearch Migration: Failed to add field: #{e.message}")
      false
    end

    # DSL method: Update documents with a Painless script
    def update_documents(script_source = nil, &block)
      return false unless indexer.send(:index_exists?)

      script = script_source || block.call

      response = indexer.send(:client).update_by_query(
        index: indexer.send(:index_name),
        body: {
          script: {
            source: script,
            lang: "painless"
          },
          query: {
            match_all: {}
          }
        },
        conflicts: "proceed",
        wait_for_completion: true,
        refresh: true
      )

      updated = response["updated"] || 0
      Rails.logger.info("OpenSearch Migration: Updated #{updated} documents")
      true
    rescue StandardError => e
      Rails.logger.error("OpenSearch Migration: Failed to update documents: #{e.message}")
      false
    end

    # DSL method: Trigger a full reindex
    def reindex_if_needed
      Rails.logger.info("OpenSearch Migration: Starting full reindex...")
      sync = OpenSearchSync.create!

      begin
        OpenSearchReindexJob.perform_now(sync.id)
        sync.reload

        if sync.completed?
          Rails.logger.info("OpenSearch Migration: Reindex completed - #{sync.indexed_cards} cards indexed")
          true
        else
          Rails.logger.error("OpenSearch Migration: Reindex failed - #{sync.error_message}")
          false
        end
      rescue StandardError => e
        Rails.logger.error("OpenSearch Migration: Reindex failed with exception: #{e.message}")
        false
      end
    end

    # Subclasses must override these
    def up
      raise NotImplementedError, "#{self.class.name} must implement #up"
    end

    def down
      # Optional - migrations don't need to implement rollback
      Rails.logger.warn("OpenSearch Migration: No down migration defined for #{name}")
    end
  end
end
