FactoryBot.define do
  factory :event do
    sequence(:title) { |n| "イベント#{n}" }
    date { Date.current + rand(1..30).days }

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