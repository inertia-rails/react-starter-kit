# frozen_string_literal: true

module Search
  class MigrationRunner
    MIGRATIONS_PATH = Rails.root.join("db", "opensearch_migrations")

    def self.run
      new.run_migrations
    end

    def self.pending
      new.pending_migrations
    end

    def self.status
      new.migration_status
    end

    def run_migrations
      pending = pending_migrations

      if pending.empty?
        puts "No pending OpenSearch migrations"
        return true
      end

      puts "Running #{pending.count} OpenSearch migration(s)..."
      puts "=" * 60

      success = true
      pending.each do |migration_info|
        success = run_single_migration(migration_info) && success
      end

      puts "=" * 60
      if success
        puts "✓ All migrations completed successfully"
      else
        puts "✗ Some migrations failed"
      end

      success
    end

    def pending_migrations
      all_migration_files.reject do |file_info|
        OpensearchMigration.exists?(version: file_info[:version])
      end
    end

    def migration_status
      all_files = all_migration_files
      applied_versions = OpensearchMigration.pluck(:version).to_set

      all_files.map do |file_info|
        {
          version: file_info[:version],
          name: file_info[:name],
          status: applied_versions.include?(file_info[:version]) ? "applied" : "pending",
          applied_at: OpensearchMigration.find_by(version: file_info[:version])&.applied_at
        }
      end
    end

    private

    def all_migration_files
      return [] unless File.directory?(MIGRATIONS_PATH)

      Dir.glob(MIGRATIONS_PATH.join("*.rb")).sort.map do |file_path|
        filename = File.basename(file_path, ".rb")
        version, *name_parts = filename.split("_")
        {
          path: file_path,
          version: version,
          name: name_parts.join("_"),
          class_name: name_parts.join("_").camelize
        }
      end
    end

    def run_single_migration(migration_info)
      puts "\n#{migration_info[:version]}_#{migration_info[:name]}"
      puts "-" * 60

      begin
        # Load the migration file
        load migration_info[:path]

        # Instantiate the migration class
        migration_class = migration_info[:class_name].constantize
        migration = migration_class.new(
          version: migration_info[:version],
          name: migration_info[:name]
        )

        # Run the up method
        start_time = Time.current
        migration.up
        duration = Time.current - start_time

        # Record the migration as applied
        OpensearchMigration.create!(
          version: migration_info[:version],
          name: migration_info[:name],
          applied_at: Time.current
        )

        puts "✓ Completed in #{duration.round(2)}s"
        true
      rescue StandardError => e
        puts "✗ Failed: #{e.message}"
        puts e.backtrace.first(3).join("\n")
        false
      end
    end
  end
end
