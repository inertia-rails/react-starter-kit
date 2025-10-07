# frozen_string_literal: true

require "rails_helper"

# Tests for CardIndexer have been moved to integration tests
# since embeddings are now stored in PostgreSQL and automatically
# included when cards are re-indexed.
RSpec.describe Search::CardIndexer do
  # TODO: Add integration tests for card indexing with embeddings
end
