FactoryBot.define do
  factory :milestone do
    association :objective
    milestone_type { %w[quality quantity].sample }
    limit_date { Date.current + rand(1..30).days }
    note { "マイルストーンの詳細" }

    trait :quality do
      milestone_type { "quality" }
    end

    trait :quantity do
      milestone_type { "quantity" }
    end

    trait :past_limit do
      limit_date { Date.current - 1.month }
    end

    trait :future_limit do
      limit_date { Date.current + 1.month }
    end

    trait :with_long_note do
      note { "a" * 1000 }
    end

    trait :with_reviews do
      after(:create) do |milestone|
        create(:milestone_review, milestone: milestone)
      end
    end
  end
end
