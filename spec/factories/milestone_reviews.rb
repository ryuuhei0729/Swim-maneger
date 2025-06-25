FactoryBot.define do
  factory :milestone_review do
    association :milestone
    achievement_rate { rand(0..100) }
    negative_note { "改善点の詳細" }
    positive_note { "良い点の詳細" }

    trait :high_achievement do
      achievement_rate { rand(80..100) }
    end

    trait :low_achievement do
      achievement_rate { rand(0..50) }
    end

    trait :with_long_notes do
      negative_note { "a" * 1000 }
      positive_note { "b" * 1000 }
    end
  end
end 