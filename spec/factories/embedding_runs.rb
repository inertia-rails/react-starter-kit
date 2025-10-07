# frozen_string_literal: true

FactoryBot.define do
  factory :embedding_run do
    status { "pending" }
    total_cards { 0 }
    processed_cards { 0 }
    failed_cards { 0 }
    batch_size { 50 }
    started_at { nil }
    completed_at { nil }
    error_message { nil }
  end
end
