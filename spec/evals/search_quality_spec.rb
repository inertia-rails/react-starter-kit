# frozen_string_literal: true

require "rails_helper"
require "yaml"

RSpec.describe "Search Quality Evaluation", type: :system do
  # Skip these tests by default - run explicitly with: rspec spec/evals/search_quality_spec.rb
  # Or run via rake task: rake search:eval
  before(:all) do
    skip "Search evals should be run explicitly" unless ENV["RUN_SEARCH_EVALS"] == "true"

    # Generate embeddings for all expected cards in test dataset
    # This enables semantic and hybrid search modes to work in tests
    self.class.ensure_test_embeddings
  end

  # Load dataset at class level for dynamic test generation
  GOLDEN_DATASET = YAML.load_file(Rails.root.join("spec/fixtures/search_evals.yml"))

  let(:search_service) { Search::CardSearch.new }

  # Helper method to ensure all expected cards have embeddings in OpenSearch
  def self.ensure_test_embeddings
    Rails.logger.info("Ensuring test embeddings are generated...")

    # Collect all expected card names from test dataset
    expected_cards = GOLDEN_DATASET.flat_map { |test| test["expected_results"] || [] }.uniq

    # Find cards in database
    cards = Card.where(name: expected_cards).includes(:card_faces, :card_legalities, :card_printings)
    found_names = cards.pluck(:name)
    missing_names = expected_cards - found_names

    if missing_names.any?
      Rails.logger.warn("Warning: Expected cards not found in database: #{missing_names.join(", ")}")
    end

    # Generate and update embeddings for found cards
    if cards.any?
      indexer = Search::CardIndexer.new
      cards.each do |card|
        # Generate embedding
        embedding = Search::EmbeddingService.embed_card(card)

        if embedding.present?
          # Update in OpenSearch
          indexer.update_card_embedding(card.id, embedding)
        else
          Rails.logger.warn("Failed to generate embedding for #{card.name}")
        end
      end

      # Refresh index to make embeddings immediately available
      indexer.refresh_index

      Rails.logger.info("Generated embeddings for #{cards.count} test cards")
    end
  rescue StandardError => e
    Rails.logger.error("Failed to generate test embeddings: #{e.message}")
    Rails.logger.error(e.backtrace.first(5).join("\n"))
  end

  # Test each search mode separately
  %w[keyword semantic hybrid].each do |search_mode|
    describe "#{search_mode} search mode" do
      let(:all_results) { [] }

      before(:all) do
        @mode_results = []
      end

      after(:all) do
        # Print summary for this mode
        print_mode_summary(search_mode, @mode_results)
      end

      GOLDEN_DATASET.each do |test_case|
        it "handles query: #{test_case["query"]}" do
          query = test_case["query"]
          expected_results = test_case["expected_results"] || []
          min_rank = test_case["min_rank"] || 5
          relevance_threshold = test_case["relevance_threshold"] || 3

          # Perform search
          results = search_service.search(
            query,
            search_mode: search_mode,
            per_page: 20
          )

          result_names = results[:results].map { |r| r["name"] || r[:name] }

          # Calculate metrics
          metrics = SearchEvalMetrics.calculate_all(result_names, expected_results, 10)

          # Store results for summary
          test_result = {
            query: query,
            description: test_case["description"],
            mode: search_mode,
            metrics: metrics,
            passed: evaluate_test_pass(metrics, min_rank, expected_results)
          }

          @mode_results << test_result

          # Optional: Use LLM-as-judge for semantic queries
          if ENV["USE_LLM_JUDGE"] == "true" && test_case["relevance_threshold"]
            judge_eval = Search::EvalJudge.evaluate_results(
              query,
              results[:results],
              expected_cards: expected_results
            )

            test_result[:llm_evaluation] = judge_eval

            # Check if LLM average score meets threshold
            if judge_eval[:average_score]
              expect(judge_eval[:average_score]).to be >= relevance_threshold,
                "LLM judge average score #{judge_eval[:average_score]} below threshold #{relevance_threshold}"
            end
          end

          # Assertions
          if expected_results.any?
            expect(metrics[:first_relevant_rank]).to be <= min_rank,
              "First relevant result at rank #{metrics[:first_relevant_rank]}, expected within #{min_rank}. " \
              "Expected: #{expected_results.join(", ")}. Got: #{result_names.first(min_rank).join(", ")}"

            expect(metrics[:total_relevant_found]).to be > 0,
              "No relevant results found in top 10. Expected: #{expected_results.join(", ")}"
          else
            # If no expected results specified, just check we got some results
            expect(results[:total]).to be > 0, "No results returned for query"
          end
        end
      end
    end
  end

  describe "Mode Comparison" do
    before(:all) do
      skip unless ENV["RUN_SEARCH_EVALS"] == "true"
    end

    it "compares search modes across all queries" do
      comparison_results = []

      GOLDEN_DATASET.each do |test_case|
        query = test_case["query"]
        expected_results = test_case["expected_results"] || []

        mode_metrics = {}

        %w[keyword semantic hybrid].each do |mode|
          results = search_service.search(query, search_mode: mode, per_page: 20)
          result_names = results[:results].map { |r| r["name"] || r[:name] }
          mode_metrics[mode] = SearchEvalMetrics.calculate_all(result_names, expected_results, 10)
        end

        comparison_results << {
          query: query,
          metrics_by_mode: mode_metrics
        }
      end

      # Print comparison summary
      print_comparison_summary(comparison_results)
    end
  end

  private

  def evaluate_test_pass(metrics, min_rank, expected_results)
    return true if expected_results.empty? # No expectations = pass

    metrics[:first_relevant_rank] &&
      metrics[:first_relevant_rank] <= min_rank &&
      metrics[:total_relevant_found] > 0
  end

  def print_mode_summary(mode, results)
    puts "\n" + "=" * 80
    puts "#{mode.upcase} SEARCH MODE SUMMARY"
    puts "=" * 80

    passed = results.count { |r| r[:passed] }
    total = results.count

    puts "Passed: #{passed}/#{total} (#{(passed.to_f / total * 100).round(1)}%)"
    puts

    # Aggregate metrics
    all_metrics = results.map { |r| r[:metrics] }
    aggregate = SearchEvalMetrics.aggregate_metrics(all_metrics)

    puts "Average Precision@10: #{aggregate[:avg_precision].round(3)}"
    puts "Average Recall@10:    #{aggregate[:avg_recall].round(3)}"
    puts "Average MRR:          #{aggregate[:avg_mrr].round(3)}"
    puts "Average NDCG@10:      #{aggregate[:avg_ndcg].round(3)}"
    puts "Median First Rank:    #{aggregate[:median_first_rank]&.round(1) || 'N/A'}"
    puts "Queries w/ No Results: #{aggregate[:queries_with_no_results]}"

    # Show failures
    failures = results.reject { |r| r[:passed] }
    if failures.any?
      puts "\nFailed Queries:"
      failures.each do |failure|
        puts "  - #{failure[:query]}"
        puts "    Rank: #{failure[:metrics][:first_relevant_rank] || 'N/A'}, " \
             "Found: #{failure[:metrics][:total_relevant_found]}"
      end
    end

    puts "=" * 80 + "\n"
  end

  def print_comparison_summary(comparison_results)
    puts "\n" + "=" * 80
    puts "SEARCH MODE COMPARISON"
    puts "=" * 80

    # Calculate aggregate metrics for each mode
    modes = %w[keyword semantic hybrid]
    mode_aggregates = {}

    modes.each do |mode|
      mode_metrics = comparison_results.map { |r| r[:metrics_by_mode][mode] }
      mode_aggregates[mode] = SearchEvalMetrics.aggregate_metrics(mode_metrics)
    end

    # Print comparison table
    puts format("%-25s", "Metric") + modes.map { |m| format("%15s", m.capitalize) }.join
    puts "-" * 80

    metrics_to_compare = [
      [:avg_precision, "Avg Precision@10"],
      [:avg_recall, "Avg Recall@10"],
      [:avg_mrr, "Avg MRR"],
      [:avg_ndcg, "Avg NDCG@10"],
      [:median_first_rank, "Median First Rank"]
    ]

    metrics_to_compare.each do |key, label|
      print format("%-25s", label)
      modes.each do |mode|
        value = mode_aggregates[mode][key]
        formatted = value ? format("%.3f", value) : "N/A"
        print format("%15s", formatted)
      end
      puts
    end

    # Find winner for each metric
    puts "\nBest performing mode by metric:"
    metrics_to_compare.each do |key, label|
      next if key == :median_first_rank # Lower is better for this

      best_mode = modes.max_by { |m| mode_aggregates[m][key] || 0 }
      puts "  #{label}: #{best_mode.capitalize}"
    end

    puts "=" * 80 + "\n"
  end
end
