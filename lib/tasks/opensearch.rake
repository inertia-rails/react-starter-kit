# frozen_string_literal: true

namespace :opensearch do
  desc "Create OpenSearch index with mappings"
  task setup: :environment do
    puts "Creating OpenSearch index..."
    indexer = Search::CardIndexer.new

    if indexer.create_index
      puts "✓ OpenSearch index created successfully"
    else
      puts "✗ Failed to create OpenSearch index"
      exit 1
    end
  end

  desc "Delete OpenSearch index"
  task delete: :environment do
    puts "Deleting OpenSearch index..."
    indexer = Search::CardIndexer.new

    if indexer.delete_index
      puts "✓ OpenSearch index deleted successfully"
    else
      puts "✗ Failed to delete OpenSearch index"
      exit 1
    end
  end

  desc "Reset OpenSearch index (delete and recreate)"
  task reset: :environment do
    puts "Resetting OpenSearch index..."
    indexer = Search::CardIndexer.new

    indexer.delete_index
    sleep 1 # Give OpenSearch a moment to process the deletion

    if indexer.create_index
      puts "✓ OpenSearch index reset successfully"
    else
      puts "✗ Failed to reset OpenSearch index"
      exit 1
    end
  end

  desc "Reindex all cards in OpenSearch"
  task reindex: :environment do
    puts "Starting OpenSearch reindex..."

    sync = OpenSearchSync.create!
    puts "Created sync record: ##{sync.id}"

    begin
      OpenSearchReindexJob.perform_now(sync.id)
      sync.reload

      if sync.completed?
        puts "✓ Reindex completed successfully"
        puts "  Total cards: #{sync.total_cards}"
        puts "  Indexed: #{sync.indexed_cards}"
        puts "  Failed: #{sync.failed_cards}"
        puts "  Duration: #{sync.duration_formatted}"
      else
        puts "✗ Reindex failed"
        puts "  Error: #{sync.error_message}"
        exit 1
      end
    rescue StandardError => e
      puts "✗ Reindex failed with exception: #{e.message}"
      puts e.backtrace.join("\n")
      exit 1
    end
  end

  desc "Show OpenSearch index status and statistics"
  task status: :environment do
    indexer = Search::CardIndexer.new

    puts "OpenSearch Status"
    puts "=" * 50

    if indexer.send(:index_exists?)
      stats = indexer.index_stats
      puts "Index: EXISTS"
      puts "Document count: #{stats[:document_count]}"
      puts "Size: #{(stats[:size_in_bytes].to_f / 1024 / 1024).round(2)} MB"
    else
      puts "Index: DOES NOT EXIST"
      puts "\nRun 'rake opensearch:setup' to create the index"
    end

    puts "\nRecent Syncs"
    puts "-" * 50

    recent_syncs = OpenSearchSync.recent.limit(5)
    if recent_syncs.any?
      recent_syncs.each do |sync|
        status_icon = case sync.status
        when "completed" then "✓"
        when "failed" then "✗"
        when "indexing" then "⟳"
        else "○"
        end

        puts "#{status_icon} ##{sync.id} - #{sync.status.upcase} - #{sync.created_at.strftime("%Y-%m-%d %H:%M:%S")}"
        if sync.total_cards > 0
          puts "  Progress: #{sync.indexed_cards}/#{sync.total_cards} (#{sync.progress_percentage}%)"
        end
        puts "  Duration: #{sync.duration_formatted}" if sync.duration
        puts "  Error: #{sync.error_message}" if sync.error_message.present?
      end
    else
      puts "No syncs found"
    end

    puts "\nDatabase Stats"
    puts "-" * 50
    puts "Total cards in database: #{Card.count}"
  end

  desc "Test OpenSearch connection"
  task test_connection: :environment do
    puts "Testing OpenSearch connection..."

    begin
      client = $OPENSEARCH_CLIENT
      info = client.info

      puts "✓ Successfully connected to OpenSearch"
      puts "  Version: #{info.dig("version", "number")}"
      puts "  Cluster: #{info["cluster_name"]}"
    rescue StandardError => e
      puts "✗ Failed to connect to OpenSearch"
      puts "  Error: #{e.message}"
      exit 1
    end
  end

  desc "Add lang field to existing index without full reindex"
  task add_lang_field: :environment do
    puts "Adding lang field to OpenSearch index..."
    puts "=" * 50
    indexer = Search::CardIndexer.new

    # Step 1: Update mapping
    puts "\n1. Updating index mapping to add 'lang' field..."
    if indexer.update_mapping
      puts "   ✓ Mapping updated successfully"
    else
      puts "   ✗ Failed to update mapping"
      exit 1
    end

    # Step 2: Update all documents
    puts "\n2. Updating all documents with lang field..."
    if indexer.update_all_documents_with_lang
      puts "   ✓ Documents updated successfully"
    else
      puts "   ✗ Failed to update documents"
      exit 1
    end

    # Step 3: Verify
    puts "\n3. Verifying changes..."
    stats = indexer.index_stats
    puts "   ✓ Index contains #{stats[:document_count]} documents"
    puts "\n" + "=" * 50
    puts "✓ Language field added successfully!"
    puts "\nAll search results will now default to English cards."
    puts "To search other languages, add a 'lang' parameter to filters."
  rescue StandardError => e
    puts "\n✗ Failed to add lang field: #{e.message}"
    puts e.backtrace.first(5).join("\n")
    exit 1
  end

  desc "Backfill embeddings for all cards"
  task backfill_embeddings: :environment do
    start_id = ENV["START_ID"]
    limit = ENV["LIMIT"]&.to_i

    puts "Starting embedding backfill..."
    puts "Start ID: #{start_id || 'beginning'}"
    puts "Limit: #{limit || 'all cards'}"
    puts "=" * 50

    result = EmbeddingBackfillJob.perform_now(start_id: start_id, limit: limit)

    puts "\n" + "=" * 50
    puts "Backfill complete!"
    puts "  Processed: #{result[:processed]}"
    puts "  Failed: #{result[:failed]}"
    puts "  Total: #{result[:total]}"
  rescue StandardError => e
    puts "✗ Backfill failed: #{e.message}"
    puts e.backtrace.first(5).join("\n")
    exit 1
  end

  desc "Test embedding generation"
  task test_embeddings: :environment do
    puts "Testing embedding generation..."
    puts "=" * 50

    test_texts = [
      "Lightning Bolt",
      "cards that let you draw cards when creatures die",
      "low cost sacrifice creatures"
    ]

    test_texts.each do |text|
      puts "\nGenerating embedding for: \"#{text}\""

      begin
        embedding = Search::EmbeddingService.embed(text)

        if embedding.present?
          puts "✓ Successfully generated embedding"
          puts "  Dimensions: #{embedding.length}"
          puts "  First 5 values: #{embedding.take(5).map { |v| v.round(4) }.join(", ")}"
        else
          puts "✗ Failed to generate embedding (returned nil)"
        end
      rescue StandardError => e
        puts "✗ Error generating embedding: #{e.message}"
        puts e.backtrace.first(3).join("\n")
      end
    end

    puts "\n" + "=" * 50
    puts "Testing card embedding..."

    begin
      card = Card.first
      if card
        puts "Card: #{card.name}"
        embedding = Search::EmbeddingService.embed_card(card)

        if embedding.present?
          puts "✓ Successfully generated card embedding"
          puts "  Dimensions: #{embedding.length}"
        else
          puts "✗ Failed to generate card embedding"
        end
      else
        puts "⚠ No cards found in database"
      end
    rescue StandardError => e
      puts "✗ Error: #{e.message}"
      puts e.backtrace.first(3).join("\n")
    end
  end

  namespace :migrate do
    desc "Run pending OpenSearch migrations"
    task run: :environment do
      Search::MigrationRunner.run
    end

    desc "Show OpenSearch migration status"
    task status: :environment do
      puts "OpenSearch Migration Status"
      puts "=" * 60

      migrations = Search::MigrationRunner.status

      if migrations.empty?
        puts "No migrations found in db/opensearch_migrations/"
        next
      end

      migrations.each do |migration|
        status_icon = migration[:status] == "applied" ? "✓" : "○"
        puts "#{status_icon} #{migration[:version]}_#{migration[:name]}"
        if migration[:applied_at]
          puts "   Applied: #{migration[:applied_at].strftime("%Y-%m-%d %H:%M:%S")}"
        end
      end

      pending_count = migrations.count { |m| m[:status] == "pending" }
      puts "\n#{pending_count} pending migration(s)" if pending_count > 0
    end

    desc "Generate a new OpenSearch migration"
    task :generate, [:name] => :environment do |_t, args|
      unless args[:name]
        puts "Error: Migration name required"
        puts "Usage: rake opensearch:migrate:generate[add_new_field]"
        exit 1
      end

      timestamp = Time.current.strftime("%Y%m%d%H%M%S")
      filename = "#{timestamp}_#{args[:name].underscore}.rb"
      filepath = Rails.root.join("db", "opensearch_migrations", filename)

      class_name = args[:name].underscore.camelize

      File.write(filepath, <<~RUBY)
        # frozen_string_literal: true

        class #{class_name} < Search::Migration
          def up
            # TODO: Implement migration
            # Examples:
            #
            # Add a field:
            #   add_field(:my_field, { type: "keyword" })
            #
            # Update documents:
            #   update_documents { "ctx._source.my_field = 'default_value'" }
            #
            # Full reindex:
            #   reindex_if_needed
          end

          def down
            # Optional: Implement rollback logic
          end
        end
      RUBY

      puts "Created migration: #{filepath}"
    end
  end
end
