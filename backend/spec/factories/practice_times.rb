FactoryBot.define do
  factory :practice_time do
    association :user
    association :practice_log
    rep_number { rand(1..10) }
    set_number { rand(1..5) }
    time { rand(20.0..120.0).round(2) }

    trait :fast_time do
      time { rand(20.0..30.0).round(2) }
    end

    trait :slow_time do
      time { rand(100.0..120.0).round(2) }
    end

    trait :first_rep do
      rep_number { 1 }
    end

    trait :last_rep do
      rep_number { 10 }
    end

    trait :first_set do
      set_number { 1 }
    end

    trait :last_set do
      set_number { 5 }
    end
  end
end
