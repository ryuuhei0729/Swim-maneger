FactoryBot.define do
  factory :user_auth do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "123123" }
    password_confirmation { "123123" }

    trait :with_user do
      association :user
    end

    trait :without_user do
      user { nil }
    end
  end
end 