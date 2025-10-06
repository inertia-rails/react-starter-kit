# frozen_string_literal: true

require "rails_helper"

RSpec.describe ScryfallBatchImportJob, type: :job do
  include ActiveJob::TestHelper

  let(:sync) { create(:scryfall_sync, :processing, sync_type: sync_type) }
  let(:sync_type) { "oracle_cards" }
  let(:batch_number) { 1 }
  let(:records) { [] }

  describe "#perform" do
    context "with oracle_cards sync type" do
      let(:sync_type) { "oracle_cards" }
      let(:records) do
        [
          {
            "oracle_id" => "test-001",
            "name" => "Test Card 1",
            "mana_cost" => "{1}{U}",
            "cmc" => 2.0,
            "type_line" => "Creature — Test",
            "oracle_text" => "Test ability",
            "colors" => ["U"],
            "color_identity" => ["U"],
            "layout" => "normal",
            "legalities" => {
              "standard" => "legal",
              "commander" => "legal"
            }
          },
          {
            "oracle_id" => "test-002",
            "name" => "Test Card 2",
            "mana_cost" => "{R}",
            "cmc" => 1.0,
            "type_line" => "Instant",
            "oracle_text" => "Deal 3 damage",
            "colors" => ["R"],
            "color_identity" => ["R"],
            "layout" => "normal",
            "legalities" => {
              "standard" => "not_legal",
              "commander" => "legal"
            }
          }
        ]
      end

      it "imports oracle cards successfully" do
        mapper = instance_double(Scryfall::CardMapper)
        allow(Scryfall::CardMapper).to receive(:new).and_return(mapper)
        expect(mapper).to receive(:import_oracle_card).with(records[0])
        expect(mapper).to receive(:import_oracle_card).with(records[1])

        perform_enqueued_jobs do
          described_class.perform_later(
            sync_id: sync.id,
            sync_type: sync_type,
            batch_number: batch_number,
            records: records
          )
        end
      end

      it "logs successful completion" do
        mapper = instance_double(Scryfall::CardMapper)
        allow(Scryfall::CardMapper).to receive(:new).and_return(mapper)
        allow(mapper).to receive(:import_oracle_card)
        allow(Rails.logger).to receive(:info)

        perform_enqueued_jobs do
          described_class.perform_later(
            sync_id: sync.id,
            sync_type: sync_type,
            batch_number: batch_number,
            records: records
          )
        end

        expect(Rails.logger).to have_received(:info)
          .with("Processing batch 1 with 2 oracle_cards records")
        expect(Rails.logger).to have_received(:info)
          .with("Completed batch 1 for oracle_cards")
      end

      it "continues processing on individual record failure" do
        mapper = instance_double(Scryfall::CardMapper)
        allow(Scryfall::CardMapper).to receive(:new).and_return(mapper)
        allow(mapper).to receive(:import_oracle_card).with(records[0])
          .and_raise(StandardError, "Import error")
        expect(mapper).to receive(:import_oracle_card).with(records[1])

        allow(Rails.logger).to receive(:error)

        perform_enqueued_jobs do
          described_class.perform_later(
            sync_id: sync.id,
            sync_type: sync_type,
            batch_number: batch_number,
            records: records
          )
        end

        expect(Rails.logger).to have_received(:error)
          .with("Failed to import oracle card test-001: Import error")
      end
    end

    context "with card printing sync types" do
      ["default_cards", "all_cards", "unique_artwork"].each do |printing_type|
        context "with #{printing_type}" do
          let(:sync_type) { printing_type }
          let(:records) do
            [
              {
                "id" => "print-001",
                "oracle_id" => "test-001",
                "name" => "Test Card",
                "set" => "tst",
                "collector_number" => "1",
                "rarity" => "common",
                "prices" => {
                  "usd" => "1.50",
                  "usd_foil" => "5.00"
                }
              }
            ]
          end

          it "imports card printings" do
            mapper = instance_double(Scryfall::CardMapper)
            allow(Scryfall::CardMapper).to receive(:new).and_return(mapper)
            expect(mapper).to receive(:import_card_printing).with(records[0], sync_type: printing_type)

            perform_enqueued_jobs do
              described_class.perform_later(
                sync_id: sync.id,
                sync_type: sync_type,
                batch_number: batch_number,
                records: records
              )
            end
          end
        end
      end
    end

    context "with rulings sync type" do
      let(:sync_type) { "rulings" }
      let(:records) do
        [
          {
            "oracle_id" => "test-001",
            "source" => "wotc",
            "published_at" => "2025-01-15",
            "comment" => "This is a test ruling"
          },
          {
            "oracle_id" => "test-002",
            "source" => "wotc",
            "published_at" => "2025-01-16",
            "comment" => "Another ruling"
          }
        ]
      end

      it "imports rulings" do
        mapper = instance_double(Scryfall::RulingMapper)
        allow(Scryfall::RulingMapper).to receive(:new).and_return(mapper)
        expect(mapper).to receive(:import_ruling).with(records[0])
        expect(mapper).to receive(:import_ruling).with(records[1])

        perform_enqueued_jobs do
          described_class.perform_later(
            sync_id: sync.id,
            sync_type: sync_type,
            batch_number: batch_number,
            records: records
          )
        end
      end

      it "handles ruling import errors" do
        mapper = instance_double(Scryfall::RulingMapper)
        allow(Scryfall::RulingMapper).to receive(:new).and_return(mapper)
        allow(mapper).to receive(:import_ruling).with(records[0])
          .and_raise(StandardError, "Ruling error")
        expect(mapper).to receive(:import_ruling).with(records[1])

        allow(Rails.logger).to receive(:error)

        perform_enqueued_jobs do
          described_class.perform_later(
            sync_id: sync.id,
            sync_type: sync_type,
            batch_number: batch_number,
            records: records
          )
        end

        expect(Rails.logger).to have_received(:error)
          .with("Failed to import ruling for test-001: Ruling error")
      end
    end

    context "with unknown sync type" do
      let(:sync_type) { "invalid_type" }

      it "logs error for unknown sync type" do
        allow(Rails.logger).to receive(:error)

        perform_enqueued_jobs do
          described_class.perform_later(
            sync_id: sync.id,
            sync_type: sync_type,
            batch_number: batch_number,
            records: records
          )
        end

        expect(Rails.logger).to have_received(:error)
          .with("Unknown sync type: invalid_type")
      end
    end

    context "batch failure handling" do
      let(:records) do
        [{"oracle_id" => "test-001", "name" => "Test Card"}]
      end

      it "increments failed_batches count on exception" do
        allow(Scryfall::CardMapper).to receive(:new)
          .and_raise(StandardError, "Mapper initialization failed")

        expect {
          perform_enqueued_jobs do
            described_class.perform_later(
              sync_id: sync.id,
              sync_type: sync_type,
              batch_number: batch_number,
              records: records
            )
          end
        }.to raise_error(StandardError, "Mapper initialization failed")

        sync.reload
        expect(sync.failed_batches).to eq 1
      end

      it "logs batch failure with backtrace" do
        allow(Scryfall::CardMapper).to receive(:new)
          .and_raise(StandardError, "Critical error")
        allow(Rails.logger).to receive(:error)

        expect {
          perform_enqueued_jobs do
            described_class.perform_later(
              sync_id: sync.id,
              sync_type: sync_type,
              batch_number: batch_number,
              records: records
            )
          end
        }.to raise_error(StandardError)

        expect(Rails.logger).to have_received(:error)
          .with("Batch 1 failed for oracle_cards: Critical error")
        expect(Rails.logger).to have_received(:error)
          .with(a_string_matching(/spec/)) # Backtrace
      end

      it "re-raises exception after logging" do
        allow(Scryfall::CardMapper).to receive(:new)
          .and_raise(StandardError, "Test error")

        expect {
          perform_enqueued_jobs do
            described_class.perform_later(
              sync_id: sync.id,
              sync_type: sync_type,
              batch_number: batch_number,
              records: records
            )
          end
        }.to raise_error(StandardError, "Test error")
      end
    end

    context "empty batch" do
      let(:records) { [] }

      it "processes empty batch without error" do
        perform_enqueued_jobs do
          described_class.perform_later(
            sync_id: sync.id,
            sync_type: sync_type,
            batch_number: batch_number,
            records: records
          )
        end

        # Should complete without creating any mappers
        expect(Scryfall::CardMapper).not_to receive(:new)
      end
    end

    context "large batch performance" do
      let(:records) do
        100.times.map do |i|
          {
            "oracle_id" => "test-#{i.to_s.rjust(3, '0')}",
            "name" => "Test Card #{i}",
            "mana_cost" => "{1}",
            "cmc" => 1.0,
            "type_line" => "Creature",
            "oracle_text" => "Test",
            "colors" => [],
            "color_identity" => [],
            "layout" => "normal",
            "legalities" => {"commander" => "legal"}
          }
        end
      end

      it "processes large batches efficiently" do
        mapper = instance_double(Scryfall::CardMapper)
        allow(Scryfall::CardMapper).to receive(:new).and_return(mapper)
        allow(mapper).to receive(:import_oracle_card)

        expect(mapper).to receive(:import_oracle_card).exactly(100).times

        perform_enqueued_jobs do
          described_class.perform_later(
            sync_id: sync.id,
            sync_type: sync_type,
            batch_number: batch_number,
            records: records
          )
        end
      end
    end
  end
end
