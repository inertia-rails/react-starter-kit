# frozen_string_literal: true

FactoryBot.define do
  factory :card_legality do
    association :card
    format { "commander" }
    status { "legal" }
  end
end
