FactoryBot.define do
  factory :race_feedback do
    association :race_goal
    association :user, :coach
    note { "レースフィードバックの詳細" }

    trait :with_long_note do
      note { "a" * 1000 }
    end

    trait :with_short_note do
      note { "短いフィードバックです。" }
    end
  end
end
