# frozen_string_literal: true

FactoryBot.define do
  factory :card do
    sequence(:oracle_id) { |n| "00000000-0000-0000-0000-#{n.to_s.rjust(12, '0')}" }
    sequence(:name) { |n| "Test Card #{n}" }
    mana_cost { "{2}{U}" }
    cmc { 3.0 }
    type_line { "Creature — Human Wizard" }
    oracle_text { "When this creature enters the battlefield, draw a card." }
    power { "2" }
    toughness { "3" }
    colors { ["U"] }
    color_identity { ["U"] }
    layout { "normal" }
    loyalty { nil }
    life_modifier { nil }
    hand_modifier { nil }
    image_status { "highres_scan" }

    trait :planeswalker do
      type_line { "Planeswalker — Jace" }
      loyalty { "4" }
      power { nil }
      toughness { nil }
    end

    trait :instant do
      type_line { "Instant" }
      power { nil }
      toughness { nil }
      oracle_text { "Counter target spell." }
    end

    trait :land do
      type_line { "Land" }
      mana_cost { nil }
      cmc { 0.0 }
      oracle_text { "{T}: Add {C}." }
      power { nil }
      toughness { nil }
    end
  end
end
