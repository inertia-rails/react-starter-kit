# frozen_string_literal: true

require "rails_helper"

RSpec.describe Search::CardSearch do
  let(:search_service) { described_class.new }
  let(:mock_client) { instance_double(OpenSearch::Client) }

  before do
    allow(search_service).to receive(:client).and_return(mock_client)
  end

  describe "#build_filter_clauses" do
    it "adds default paper-only filter" do
      filter_clauses = search_service.send(:build_filter_clauses, {})

      paper_filter = filter_clauses.find { |f| f.dig(:term, :games) == "paper" }
      expect(paper_filter).to be_present
    end

    it "does not add paper filter when arena is specified in games" do
      filter_clauses = search_service.send(:build_filter_clauses, {games: ["arena"]})

      paper_filter = filter_clauses.find { |f| f.dig(:term, :games) == "paper" }
      expect(paper_filter).to be_nil
    end

    it "does not add paper filter when mtgo is specified in games" do
      filter_clauses = search_service.send(:build_filter_clauses, {games: ["mtgo"]})

      paper_filter = filter_clauses.find { |f| f.dig(:term, :games) == "paper" }
      expect(paper_filter).to be_nil
    end

    it "excludes non-playable layouts by default" do
      filter_clauses = search_service.send(:build_filter_clauses, {})

      layout_filter = filter_clauses.find { |f| f.dig(:bool, :must_not, :terms, :layout).present? }
      expect(layout_filter).to be_present
      expect(layout_filter[:bool][:must_not][:terms][:layout]).to include("token", "art_series", "emblem")
    end

    it "includes tokens when include_tokens is true" do
      filter_clauses = search_service.send(:build_filter_clauses, {include_tokens: "true"})

      layout_filter = filter_clauses.find { |f| f.dig(:bool, :must_not, :terms, :layout).present? }
      expect(layout_filter).to be_nil
    end

    it "includes tokens when token type is searched" do
      filter_clauses = search_service.send(:build_filter_clauses, {types: ["Token"]})

      layout_filter = filter_clauses.find { |f| f.dig(:bool, :must_not, :terms, :layout).present? }
      expect(layout_filter).to be_nil
    end

    it "adds legality requirement filter" do
      filter_clauses = search_service.send(:build_filter_clauses, {})

      legality_filter = filter_clauses.find { |f| f.dig(:bool, :should, 0, :terms, :"legalities.standard") == ["legal", "restricted", "banned"] }
      expect(legality_filter).to be_present
      expect(legality_filter[:bool][:minimum_should_match]).to eq(1)
    end

    it "adds language filter defaulting to English" do
      filter_clauses = search_service.send(:build_filter_clauses, {})

      lang_filter = filter_clauses.find { |f| f.dig(:term, :lang) == "en" }
      expect(lang_filter).to be_present
    end
  end

  describe "#search" do
    let(:mock_response) do
      {
        "hits" => {
          "hits" => [
            {
              "_id" => "1",
              "_score" => 10.5,
              "_source" => {
                "name" => "Lightning Bolt",
                "type_line" => "Instant",
                "games" => ["paper", "mtgo"],
                "layout" => "normal"
              }
            }
          ],
          "total" => {"value" => 1}
        }
      }
    end

    before do
      allow(mock_client).to receive(:search).and_return(mock_response)
    end

    it "applies default filters in keyword search" do
      expect(mock_client).to receive(:search) do |args|
        query = args[:body][:query]
        # For keyword search, filters are in function_score -> query -> bool -> filter
        filter_clauses = query.dig(:function_score, :query, :bool, :filter)

        # Verify paper-only filter
        paper_filter = filter_clauses&.find { |f| f.dig(:term, :games) == "paper" }
        expect(paper_filter).to be_present

        # Verify layout filter
        layout_filter = filter_clauses&.find { |f| f.dig(:bool, :must_not, :terms, :layout).present? }
        expect(layout_filter).to be_present

        # Verify legality filter
        legality_filter = filter_clauses&.find { |f| f.dig(:bool, :should, 0, :terms, :"legalities.standard") == ["legal", "restricted", "banned"] }
        expect(legality_filter).to be_present
        expect(legality_filter[:bool][:minimum_should_match]).to eq(1)

        mock_response
      end

      # Use a query that will trigger keyword search mode
      search_service.search("dragon", filters: {}, page: 1, per_page: 20, search_mode: "keyword")
    end

    it "applies ranking boosts in keyword search" do
      expect(mock_client).to receive(:search) do |args|
        query = args[:body][:query]
        functions = query.dig(:function_score, :functions)

        expect(functions).to be_present
        expect(functions.length).to eq(2)

        # Check EDHREC ranking function
        edhrec_function = functions.find { |f| f.dig(:filter, :exists, :field) == "edhrec_rank" }
        expect(edhrec_function).to be_present
        expect(edhrec_function[:weight]).to eq(1.5)

        # Check recency function
        recency_function = functions.find { |f| f.dig(:filter, :range, :released_at).present? }
        expect(recency_function).to be_present
        expect(recency_function[:weight]).to eq(1.3)

        mock_response
      end

      search_service.search("lightning", filters: {}, page: 1, per_page: 20)
    end

    it "respects include_tokens filter" do
      expect(mock_client).to receive(:search) do |args|
        query = args[:body][:query]
        filter_clauses = query.dig(:function_score, :query, :bool, :filter)

        layout_filter = filter_clauses.find { |f| f.dig(:bool, :must_not, :terms, :layout).present? }
        expect(layout_filter).to be_nil

        mock_response
      end

      search_service.search("goblin", filters: {include_tokens: "true"}, page: 1, per_page: 20)
    end

    it "allows digital cards when games filter includes arena" do
      expect(mock_client).to receive(:search) do |args|
        query = args[:body][:query]
        filter_clauses = query.dig(:function_score, :query, :bool, :filter)

        paper_filter = filter_clauses.find { |f| f.dig(:term, :games) == "paper" }
        expect(paper_filter).to be_nil

        mock_response
      end

      search_service.search("some card", filters: {games: ["arena"]}, page: 1, per_page: 20)
    end
  end

  describe "#autocomplete" do
    let(:mock_response) do
      {
        "hits" => {
          "hits" => [
            {
              "_id" => "1",
              "_source" => {
                "name" => "Lightning Bolt",
                "type_line" => "Instant",
                "mana_cost" => "{R}"
              }
            }
          ]
        }
      }
    end

    before do
      allow(mock_client).to receive(:search).and_return(mock_response)
    end

    it "returns autocomplete results" do
      results = search_service.autocomplete("light", limit: 10)

      expect(results).to be_an(Array)
      expect(results.first[:name]).to eq("Lightning Bolt")
    end
  end
end
