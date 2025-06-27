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

    trait :with_reviews do
      after(:create) do |race_goal|
        create(:race_review, race_goal: race_goal)
      end
    end

    trait :with_feedbacks do
      after(:create) do |race_goal|
        create(:race_feedback, race_goal: race_goal)
      end
    end
  end
end
