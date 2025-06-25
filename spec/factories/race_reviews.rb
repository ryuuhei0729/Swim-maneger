FactoryBot.define do
  factory :race_review do
    association :race_goal
    association :style
    time { rand(20.0..120.0).round(2) }
    note { "レースレビューの詳細" }

    trait :fast_time do
      time { rand(20.0..30.0).round(2) }
    end

    trait :slow_time do
      time { rand(100.0..120.0).round(2) }
    end

    trait :with_long_note do
      note { "a" * 1000 }
    end
  end
end 