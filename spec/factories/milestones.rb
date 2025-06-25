FactoryBot.define do
  factory :milestone do
    association :objective
    milestone_type { "quality" }
    limit_date { Date.current + 1.month }
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
  end
end 