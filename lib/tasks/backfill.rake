# frozen_string_literal: true

namespace :backfill do
  desc "Backfill lang field for existing card printings (sets all to 'en')"
  task card_printing_languages: :environment do
    puts "Backfilling lang field for CardPrintings..."
    puts "=" * 50

    total = CardPrinting.where(lang: nil).or(CardPrinting.where(lang: "")).count

    if total.zero?
      puts "No printings need backfilling - all have lang set"
      next
    end

    puts "Found #{total} printings without lang set"
    puts "Setting all to 'en' (English)..."

    updated = 0
    CardPrinting.where(lang: nil).or(CardPrinting.where(lang: "")).in_batches(of: 1000) do |batch|
      batch.update_all(lang: "en")
      updated += batch.count
      print "\rUpdated: #{updated}/#{total}"
    end

    puts "\n" + "=" * 50
    puts "✓ Backfill complete! Updated #{updated} printings"
  end
end
