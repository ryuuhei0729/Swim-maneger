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
  end
end
