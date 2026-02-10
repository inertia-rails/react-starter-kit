# frozen_string_literal: true

FactoryBot.define do
  factory :todo do
    association :user
    sequence(:title) { |n| "Todo item #{n}" }
    completed { false }
  end
end
