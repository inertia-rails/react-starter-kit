# frozen_string_literal: true

require "rails_helper"

RSpec.describe Search::CardIndexer do
  let(:indexer) { described_class.new }
  let(:card) { create(:card) }
  let(:mock_client) { double("OpenSearch Client") }

  before do
    allow(indexer).to receive(:client).and_return(mock_client)
  end

  describe "#update_card_embedding" do
    let(:embedding) { Array.new(1536) { rand } }

    context "with valid embedding" do
      it "updates the embedding field in OpenSearch" do
        expect(mock_client).to receive(:update).with(
          index: "cards",
          id: card.id,
          body: {
            doc: {
              embedding: embedding
            }
          }
        )

        result = indexer.update_card_embedding(card.id, embedding)
        expect(result).to be true
      end
    end

    context "with blank embedding" do
      it "returns false without calling OpenSearch" do
        expect(mock_client).not_to receive(:update)

        result = indexer.update_card_embedding(card.id, nil)
        expect(result).to be false
      end
    end

    context "when card not found in index" do
      it "returns false and logs warning" do
        allow(mock_client).to receive(:update).and_raise(
          OpenSearch::Transport::Transport::Errors::NotFound
        )
        expect(Rails.logger).to receive(:warn).with(/Card #{card.id} not found in index/)

        result = indexer.update_card_embedding(card.id, embedding)
        expect(result).to be false
      end
    end

    context "when OpenSearch error occurs" do
      it "returns false and logs error" do
        allow(mock_client).to receive(:update).and_raise(StandardError.new("Connection failed"))
        expect(Rails.logger).to receive(:error).with(/Failed to update embedding for card #{card.id}/)

        result = indexer.update_card_embedding(card.id, embedding)
        expect(result).to be false
      end
    end
  end

  describe "#bulk_update_embeddings" do
    let(:embedding1) { Array.new(1536) { rand } }
    let(:embedding2) { Array.new(1536) { rand } }
    let(:updates) do
      [
        {id: 1, embedding: embedding1},
        {id: 2, embedding: embedding2}
      ]
    end

    context "with valid updates" do
      it "performs bulk update in OpenSearch" do
        expect(mock_client).to receive(:bulk).with(
          body: [
            {update: {_index: "cards", _id: 1}},
            {doc: {embedding: embedding1}},
            {update: {_index: "cards", _id: 2}},
            {doc: {embedding: embedding2}}
          ]
        ).and_return({"errors" => false})

        result = indexer.bulk_update_embeddings(updates)
        expect(result).to be true
      end
    end

    context "with empty updates array" do
      it "returns true without calling OpenSearch" do
        expect(mock_client).not_to receive(:bulk)

        result = indexer.bulk_update_embeddings([])
        expect(result).to be true
      end
    end

    context "when bulk update has errors" do
      it "returns false and logs errors" do
        allow(mock_client).to receive(:bulk).and_return(
          {
            "errors" => true,
            "items" => [
              {
                "update" => {
                  "_id" => 1,
                  "error" => {
                    "reason" => "Document not found"
                  }
                }
              }
            ]
          }
        )
        expect(Rails.logger).to receive(:error).with(/Bulk embedding update had 1 errors/)
        expect(Rails.logger).to receive(:error).with(/Error for card 1: Document not found/)

        result = indexer.bulk_update_embeddings(updates)
        expect(result).to be false
      end
    end

    context "when OpenSearch error occurs" do
      it "returns false and logs error" do
        allow(mock_client).to receive(:bulk).and_raise(StandardError.new("Connection failed"))
        expect(Rails.logger).to receive(:error).with(/Bulk embedding update failed/)

        result = indexer.bulk_update_embeddings(updates)
        expect(result).to be false
      end
    end
  end
end
