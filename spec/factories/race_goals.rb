FactoryBot.define do
  factory :race_goal do
    association :user
    association :attendance_event
    association :style
    time { rand(20.0..120.0).round(2) }
    note { "レース目標の詳細" }

    trait :fast_goal do
      time { rand(20.0..30.0).round(2) }
    end

    trait :slow_goal do
      time { rand(100.0..120.0).round(2) }
    end

    trait :with_long_note do
      note { "a" * 1000 }
    end
  end
end
