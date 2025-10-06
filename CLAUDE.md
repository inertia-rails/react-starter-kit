# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Development

```bash
# Start the application (includes Vite, Rails server, Sidekiq worker, and Docker services)
bin/dev

# Start Sidekiq worker separately (if not using bin/dev)
bundle exec sidekiq -C config/sidekiq.yml

# Setup the application initially
bin/setup

# Rails console
bin/rails console
```

### Testing

```bash
# Run all RSpec tests
bundle exec rspec

# Run specific test file with detailed output
RAILS_ENV=test bundle exec rspec spec/models/scryfall_sync_spec.rb --format documentation --no-color

# Run with test coverage report
COVERAGE=true bundle exec rspec
```

### Code Quality

```bash
# TypeScript type checking
npm run check

# JavaScript/TypeScript linting
npm run lint
npm run lint:fix

# Code formatting with Prettier
npm run format
npm run format:fix

# Ruby linting with RuboCop (autocorrect enabled by default)
rake
# or explicitly
rake rubocop:autocorrect
```

### Scryfall Data Sync

```bash
# Sync specific data types
rake scryfall:sync:oracle_cards   # Core card data
rake scryfall:sync:rulings        # Card rulings
rake scryfall:sync:default_cards  # One printing per card
rake scryfall:sync:unique_artwork # Unique artwork cards
rake scryfall:sync:all_cards     # All printings (large dataset)

# Check sync status
rake scryfall:status

# Process already downloaded data
rake scryfall:process[oracle_cards]
```

### Automated Background Jobs

The application runs automated cron jobs via Sidekiq-Cron (configured in `config/schedule.yml`):

```bash
# View scheduled jobs in Sidekiq Web UI
open http://localhost:3000/jobs

# Check in Rails console
Sidekiq::Cron::Job.all
```

**Automated Jobs:**
- **Every hour at :15** - Sync default_cards (canonical card images)
- **Daily at 06:00 UTC** - Sync all_cards (complete printing data)
- **Every hour at :30** - Generate embeddings for cards without them (up to 100/hour)
- **Every hour at :12** - Clear finished job stats

See `docs/scryfall-sync.md` for complete job flow diagram and details.

### OpenSearch Card Search

```bash
# Setup and manage OpenSearch index
rake opensearch:setup           # Create index with mappings
rake opensearch:reindex         # Reindex all cards
rake opensearch:reset          # Delete and recreate index
rake opensearch:status         # Check index health and stats
rake opensearch:test_connection # Verify OpenSearch connectivity
rake opensearch:delete         # Remove index

# Admin dashboard for monitoring
# Visit /admin/open_search_syncs (requires admin login)

# API endpoints (no authentication required)
# GET /api/cards/autocomplete?q=lightning
# GET /api/cards/search?q=dragon&colors[]=R&cmc_min=4&cmc_max=6
```

## Architecture

### Stack Overview

- **Backend**: Rails 8 with PostgreSQL, Redis, and Sidekiq for background jobs
- **Frontend**: React with TypeScript, Inertia.js for SSR, Vite for bundling
- **UI Components**: Radix UI primitives with Tailwind CSS
- **Testing**: RSpec for backend, comprehensive factory and fixture setup

### Key Architectural Patterns

1. **Inertia.js Integration**: Pages are React components served via Rails controllers using `inertia` render method. Props are passed from controllers to React pages seamlessly.

2. **Background Job Processing**: Uses Sidekiq for background jobs and Sidekiq-Cron for scheduled jobs
   - **Sync Jobs**: `ScryfallSyncJob`, `ScryfallProcessingJob`, `ScryfallBatchImportJob`
   - **Automated Sync**: `ScryfallDefaultCardsSyncJob` (hourly), `ScryfallAllCardsSyncJob` (daily)
   - **Embedding Jobs**: `HourlyEmbeddingGenerationJob`, `EmbeddingBackfillJob`
   - **Search Jobs**: `OpenSearchCardUpdateJob`, `OpenSearchReindexJob`

3. **State Machine Pattern**: `ScryfallSync` model uses AASM for state transitions (pending → downloading → completed/failed)

4. **Service Objects**: Card data mapping logic is extracted to service objects in `app/services/scryfall/` for testability and separation of concerns

5. **Batch Processing**: Large datasets are processed in configurable batches (default 500 records) to manage memory usage and enable parallel processing

### Data Model

Core models for Magic: The Gathering data:
- `Card`: Oracle card data (canonical version with `embeddings_generated_at` timestamp)
- `CardSet`: Sets and expansions
- `CardPrinting`: Individual printings of cards (includes `is_default` flag for canonical images)
- `CardFace`: Multi-faced card data
- `CardRuling`: Official rulings
- `CardLegality`: Format legalities
- `RelatedCard`: Card relationships (tokens, meld, etc.)
- `ScryfallSync`: Tracks sync operations with progress and state machine
- `EmbeddingRun`: Tracks embedding generation runs
- `OpenSearchSync`: Tracks OpenSearch reindex operations
- `OpensearchMigration`: Tracks applied OpenSearch migrations

### Automated Workflows

1. **Default Printing System**:
   - Hourly sync of `default_cards` marks canonical printings with `is_default: true`
   - OpenSearch uses default printing for card images in search results
   - When default changes, `CardPrinting` after_commit callback triggers OpenSearch reindex
   - Daily sync of `all_cards` keeps complete printing data for deck builder

2. **Embedding Generation**:
   - Hourly job finds up to 100 cards without embeddings
   - Generates semantic embeddings via OpenAI API (`text-embedding-3-small`)
   - Re-indexes cards in OpenSearch with embeddings for hybrid search
   - Can be invalidated via OpenSearch migrations to force regeneration

3. **OpenSearch Migrations**:
   - Auto-run on deploy via `docker-entrypoint`
   - Versioned like Rails migrations in `db/opensearch_migrations/`
   - Support field additions, document updates, and reindexing
   - Tracked in `opensearch_migrations` table

### Frontend Structure

- `app/frontend/pages/`: Inertia page components
- `app/frontend/components/`: Reusable UI components
- `app/frontend/layouts/`: Layout wrappers
- `app/frontend/hooks/`: Custom React hooks
- `app/frontend/lib/`: Utility functions and helpers

### Authentication

Uses authentication-zero with bcrypt for user authentication, including:
- Session-based authentication
- Email verification flow
- Password reset functionality
- Multiple session management

### Background Job Monitoring

Sidekiq Web UI mounted at `/jobs` (requires admin authentication) for monitoring background jobs, providing visibility into:
- Queue sizes and latency
- Job processing statistics
- Failed jobs and retries
- Scheduled and recurring jobs (via Sidekiq-Cron)

## Database

Uses PostgreSQL with Docker Compose for development. The database includes:
- Solid Cache for Rails caching
- Solid Cable for Action Cable support

Uses Redis for:
- Sidekiq job queue and processing
- Application caching (optional)

Docker services (PostgreSQL, Redis, OpenSearch) are automatically started with `bin/dev`.