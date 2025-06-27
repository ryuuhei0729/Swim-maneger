FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "ユーザー#{n}" }
    generation { rand(60..95) }
    gender { %w[male female].sample }
    birthday { Date.new(rand(1990..2010), rand(1..12), rand(1..28)) }
    user_type { %w[player coach director manager].sample }
    bio { "水泳が大好きな選手です。" }

    trait :player do
      user_type { "player" }
    end

    trait :coach do
      user_type { "coach" }
    end

    trait :director do
      user_type { "director" }
    end

    trait :manager do
      user_type { "manager" }
    end

    trait :male do
      gender { "male" }
    end

    trait :female do
      gender { "female" }
    end

    trait :with_user_auth do
      after(:create) do |user|
        create(:user_auth, user: user)
      end
    end
  end
end
