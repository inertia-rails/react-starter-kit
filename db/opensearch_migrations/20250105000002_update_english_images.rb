# frozen_string_literal: true

class UpdateEnglishImages < Search::Migration
  def up
    # This migration requires a full reindex because we need to
    # re-run the card_document logic which now filters for English printings
    reindex_if_needed
  end

  def down
    # No rollback needed - reindexing is idempotent
  end
end
