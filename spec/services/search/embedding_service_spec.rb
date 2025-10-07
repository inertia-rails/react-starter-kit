# frozen_string_literal: true

require "rails_helper"

RSpec.describe Search::EmbeddingService do
  describe ".embed" do
    context "with valid text" do
      let(:text) { "Lightning Bolt" }
      let(:mock_embedding) { Array.new(1536) { rand } }
      let(:mock_response) { double(vectors: mock_embedding) }

      before do
        allow(RubyLLM).to receive(:embed).and_return(mock_response)
      end

      it "returns an embedding vector" do
        result = described_class.embed(text)
        expect(result).to be_an(Array)
        expect(result.length).to eq(1536)
      end

      it "normalizes the text before embedding" do
        text_with_whitespace = "Lightning    Bolt\n\nDeal 3 damage"
        expect(RubyLLM).to receive(:embed).with("Lightning Bolt Deal 3 damage").and_return(mock_response)

        described_class.embed(text_with_whitespace)
      end
    end

    context "with blank text" do
      it "returns nil for empty string" do
        expect(described_class.embed("")).to be_nil
      end

      it "returns nil for nil" do
        expect(described_class.embed(nil)).to be_nil
      end

      it "returns nil for whitespace only" do
        expect(described_class.embed("   \n  ")).to be_nil
      end
    end

    context "when API call fails" do
      before do
        allow(RubyLLM).to receive(:embed).and_raise(StandardError.new("API error"))
      end

      it "returns nil and logs error" do
        expect(Rails.logger).to receive(:error).at_least(:once)
        result = described_class.embed("test")
        expect(result).to be_nil
      end
    end

    context "with very long text" do
      let(:long_text) { "a" * 10000 }
      let(:mock_embedding) { Array.new(1536) { rand } }
      let(:mock_response) { double(vectors: mock_embedding) }

      before do
        allow(RubyLLM).to receive(:embed).and_return(mock_response)
      end

      it "truncates text to 8000 characters" do
        expect(RubyLLM).to receive(:embed).with("a" * 8000).and_return(mock_response)

        described_class.embed(long_text)
      end
    end
  end

  describe ".embed_batch" do
    context "with valid texts" do
      let(:texts) { ["Lightning Bolt", "Dark Ritual"] }
      let(:mock_embeddings) do
        [
          Array.new(1536) { rand },
          Array.new(1536) { rand }
        ]
      end
      let(:mock_response) { double(vectors: mock_embeddings) }

      before do
        allow(RubyLLM).to receive(:embed).and_return(mock_response)
      end

      it "returns an array of embeddings" do
        result = described_class.embed_batch(texts)
        expect(result).to be_an(Array)
        expect(result.length).to eq(2)
        expect(result.first.length).to eq(1536)
      end

      it "calls RubyLLM.embed with array of texts" do
        expect(RubyLLM).to receive(:embed).with(["Lightning Bolt", "Dark Ritual"]).and_return(mock_response)
        described_class.embed_batch(texts)
      end
    end

    context "with empty array" do
      it "returns empty array" do
        expect(described_class.embed_batch([])).to eq([])
      end
    end

    context "when API call fails" do
      before do
        allow(RubyLLM).to receive(:embed).and_raise(StandardError.new("API error"))
      end

      it "returns empty array and logs error" do
        expect(Rails.logger).to receive(:error).at_least(:once)
        result = described_class.embed_batch(["test"])
        expect(result).to eq([])
      end
    end
  end

  describe ".embed_cards_batch" do
    context "with valid cards" do
      let(:cards) { create_list(:card, 3) }
      let(:mock_embeddings) do
        [
          Array.new(1536) { rand },
          Array.new(1536) { rand },
          Array.new(1536) { rand }
        ]
      end
      let(:mock_response) { double(vectors: mock_embeddings) }

      before do
        allow(RubyLLM).to receive(:embed).and_return(mock_response)
      end

      it "returns embeddings for all cards" do
        result = described_class.embed_cards_batch(cards)
        expect(result).to be_an(Array)
        expect(result.length).to eq(3)
        expect(result.first.length).to eq(1536)
      end

      it "converts cards to text before embedding" do
        expect(RubyLLM).to receive(:embed) do |texts|
          expect(texts).to be_an(Array)
          expect(texts.length).to eq(3)
          expect(texts.first).to include(cards.first.name)
          mock_response
        end
        described_class.embed_cards_batch(cards)
      end
    end

    context "with empty array" do
      it "returns empty array" do
        expect(described_class.embed_cards_batch([])).to eq([])
      end
    end
  end

  describe ".embed_card" do
    let(:card) { create(:card) }
    let(:mock_embedding) { Array.new(1536) { rand } }
    let(:mock_response) { double(vectors: mock_embedding) }

    before do
      allow(RubyLLM).to receive(:embed).and_return(mock_response)
    end

    it "generates embedding from card attributes" do
      result = described_class.embed_card(card)
      expect(result).to be_an(Array)
      expect(result.length).to eq(1536)
    end

    it "includes card name, type, and oracle text" do
      expect(RubyLLM).to receive(:embed) do |text|
        expect(text).to include(card.name)
        expect(text).to include(card.type_line)
        mock_response
      end

      described_class.embed_card(card)
    end

    context "with multi-faced card" do
      # TODO: Add factory for card_face and enable this test
      xit "includes card face information" do
      end
    end
  end

  describe ".embed_card_document" do
    let(:card_doc) do
      {
        name: "Lightning Bolt",
        type_line: "Instant",
        oracle_text: "Lightning Bolt deals 3 damage to any target.",
        keywords: ["Instant"],
        card_faces: []
      }
    end
    let(:mock_embedding) { Array.new(1536) { rand } }
    let(:mock_response) { double(vectors: mock_embedding) }

    before do
      allow(RubyLLM).to receive(:embed).and_return(mock_response)
    end

    it "generates embedding from card document hash" do
      result = described_class.embed_card_document(card_doc)
      expect(result).to be_an(Array)
      expect(result.length).to eq(1536)
    end

    it "includes all relevant fields" do
      expect(RubyLLM).to receive(:embed) do |text|
        expect(text).to include("Lightning Bolt")
        expect(text).to include("Instant")
        mock_response
      end

      described_class.embed_card_document(card_doc)
    end
  end
end
