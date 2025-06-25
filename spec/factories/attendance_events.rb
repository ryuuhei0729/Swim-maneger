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

    trait :future do
      date { Date.current + rand(1..30).days }
    end

    trait :past do
      date { Date.current - rand(1..30).days }
    end

    trait :today do
      date { Date.current }
    end
  end
end 