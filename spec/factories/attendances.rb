FactoryBot.define do
  factory :attendance do
    association :user
    association :attendance_event
    status { "present" }
    note { "" }

    trait :present do
      status { "present" }
      note { "" }
    end

    trait :absent do
      status { "absent" }
      note { "体調不良のため欠席" }
    end

    trait :other do
      status { "other" }
      note { "遅刻予定" }
    end

    trait :without_note do
      note { "" }
    end

    trait :with_long_note do
      note { "a" * 1000 }
    end
  end
end
