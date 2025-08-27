FactoryBot.define do
  factory :user_auth do
    association :user
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }

    trait :with_user do
      association :user
    end

    trait :without_user do
      user { nil }
    end

    trait :player do
      association :user, :player
    end

    trait :coach do
      association :user, :coach
    end

    trait :director do
      association :user, :director
    end

    trait :manager do
      association :user, :manager
    end

    trait :admin do
      association :user, :coach
    end
  end
end
