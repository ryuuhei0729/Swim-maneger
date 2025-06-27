FactoryBot.define do
  factory :objective do
    association :user
    association :attendance_event
    association :style
    target_time { rand(30.0..120.0) }
    quantity_note { "量の目標に関する詳細" }
    quality_title { "質の目標タイトル" }
    quality_note { "質の目標に関する詳細" }

    trait :fast_target do
      target_time { rand(20.0..30.0).round(2) }
    end

    trait :slow_target do
      target_time { rand(100.0..120.0).round(2) }
    end

    trait :with_long_notes do
      quantity_note { "a" * 1000 }
      quality_note { "b" * 1000 }
    end

    trait :with_milestones do
      after(:create) do |objective|
        create(:milestone, objective: objective)
      end
    end

    trait :quality_milestone do
      after(:create) do |objective|
        create(:milestone, :quality, objective: objective)
      end
    end

    trait :quantity_milestone do
      after(:create) do |objective|
        create(:milestone, :quantity, objective: objective)
      end
    end
  end
end
