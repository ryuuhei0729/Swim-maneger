FactoryBot.define do
  factory :attendance_event do
    sequence(:title) { |n| "イベント#{n}" }
    date { Date.current + rand(1..30).days }
    place { "市営プール" }
    note { "練習内容の詳細" }
    is_competition { false }

    trait :competition do
      is_competition { true }
      title { "大会" }
    end

    trait :practice do
      is_competition { false }
      title { "練習" }
    end

    trait :future_date do
      date { Date.current + rand(1..30).days }
    end

    trait :past_date do
      date { Date.current - rand(1..30).days }
    end

    trait :future do
      date { Date.current + rand(1..30).days }
    end

    trait :past do
      date { Date.current - rand(1..30).days }
    end

    trait :today do
      date { Date.current }
    end

    trait :with_attendance do
      after(:create) do |event|
        create(:attendance, attendance_event: event)
      end
    end

    trait :with_records do
      after(:create) do |event|
        create(:record, attendance_event: event)
      end
    end

    trait :with_objectives do
      after(:create) do |event|
        create(:objective, attendance_event: event)
      end
    end

    trait :with_race_goals do
      after(:create) do |event|
        create(:race_goal, attendance_event: event)
      end
    end
  end
end
