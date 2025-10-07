# frozen_string_literal: true

require "rails_helper"

RSpec.describe EmbeddingBackfillJob, type: :job do
  let(:embedding_run) { create(:embedding_run) }
  let!(:cards_without_embeddings) do
    create_list(:card, 5, embeddings_generated_at: nil).tap do |cards|
      cards.each do |card|
        create(:card_legality, card: card, format: "commander", status: "legal")
      end
    end
  end
  let!(:cards_with_embeddings) do
    create_list(:card, 2, embeddings_generated_at: 1.day.ago).tap do |cards|
      cards.each do |card|
        create(:card_legality, card: card, format: "commander", status: "legal")
      end
    end
  end

  let(:mock_indexer) { instance_double(Search::CardIndexer) }
  let(:mock_embeddings) { Array.new(5) { Array.new(1536) { rand } } }

  before do
    allow(Search::CardIndexer).to receive(:new).and_return(mock_indexer)
    allow(mock_indexer).to receive(:refresh_index)
    allow(Search::EmbeddingService).to receive(:embed_cards_batch).and_return(mock_embeddings)
    allow(mock_indexer).to receive(:bulk_update_embeddings).and_return(true)
  end

  describe "#perform" do
    it "processes cards without embeddings" do
      described_class.new.perform(embedding_run.id)

      cards_without_embeddings.each(&:reload)
      expect(cards_without_embeddings.all? { |card| card.embeddings_generated_at.present? }).to be true
    end

    it "does not process cards with embeddings" do
      timestamp = cards_with_embeddings.first.embeddings_generated_at

      described_class.new.perform(embedding_run.id)

      cards_with_embeddings.first.reload
      expect(cards_with_embeddings.first.embeddings_generated_at).to eq(timestamp)
    end

    it "calls batch API once per batch" do
      expect(Search::EmbeddingService).to receive(:embed_cards_batch).once.with(
        an_instance_of(Array)
      ).and_return(mock_embeddings)

      described_class.new.perform(embedding_run.id)
    end

    it "updates OpenSearch with bulk updates" do
      expect(mock_indexer).to receive(:bulk_update_embeddings).with(
        an_instance_of(Array)
      ).and_return(true)

      described_class.new.perform(embedding_run.id)
    end

    it "marks embedding run as complete" do
      described_class.new.perform(embedding_run.id)

      embedding_run.reload
      expect(embedding_run.status).to eq("completed")
    end

    context "when batch embedding fails" do
      before do
        allow(Search::EmbeddingService).to receive(:embed_cards_batch).and_return([])
      end

      it "continues processing without crashing" do
        expect { described_class.new.perform(embedding_run.id) }.not_to raise_error
      end

      it "marks cards as failed" do
        described_class.new.perform(embedding_run.id)

        embedding_run.reload
        expect(embedding_run.failed_cards).to eq(5)
      end
    end

    context "when OpenSearch update fails" do
      before do
        allow(mock_indexer).to receive(:bulk_update_embeddings).and_return(false)
      end

      it "marks cards as failed" do
        described_class.new.perform(embedding_run.id)

        embedding_run.reload
        expect(embedding_run.failed_cards).to eq(5)
      end

      it "does not mark cards with embeddings_generated_at" do
        described_class.new.perform(embedding_run.id)

        cards_without_embeddings.each(&:reload)
        expect(cards_without_embeddings.all? { |card| card.embeddings_generated_at.nil? }).to be true
      end
    end

    context "with limit parameter" do
      it "respects the limit" do
        described_class.new.perform(embedding_run.id, limit: 3)

        cards_with_embeddings_count = cards_without_embeddings.count { |card| card.reload.embeddings_generated_at.present? }
        expect(cards_with_embeddings_count).to eq(3)
      end
    end

    context "with start_id parameter" do
      it "starts from the specified ID" do
        # Sort cards by ID to ensure we're using the correct order
        sorted_cards = cards_without_embeddings.sort_by(&:id)
        start_id = sorted_cards[2].id

        # Mock embeddings for only the cards that will be processed (3 cards)
        mock_partial_embeddings = Array.new(3) { Array.new(1536) { rand } }
        allow(Search::EmbeddingService).to receive(:embed_cards_batch).and_return(mock_partial_embeddings)

        described_class.new.perform(embedding_run.id, start_id: start_id)

        # First two cards should not be processed
        sorted_cards[0..1].each do |card|
          card.reload
          expect(card.embeddings_generated_at).to be_nil
        end

        # Remaining cards should be processed
        sorted_cards[2..].each do |card|
          card.reload
          expect(card.embeddings_generated_at).to be_present
        end
      end
    end
  end
end
