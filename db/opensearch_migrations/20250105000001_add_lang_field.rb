# frozen_string_literal: true

class AddLangField < Search::Migration
  def up
    # Step 1: Add lang field to mapping
    add_field(:lang, {type: "keyword"})

    # Step 2: Update all documents with lang field from _source
    # Cards already have lang in their _source, this just makes it searchable
    update_documents { "ctx._source.lang = ctx._source.lang ?: 'en'" }
  end

  def down
    # OpenSearch doesn't really support removing fields from mapping
    # The field will just be ignored if not populated
  end
end
