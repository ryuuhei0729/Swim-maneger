FactoryBot.define do
  factory :entry do
    association :user
    association :attendance_event
    association :style
    entry_time { rand(30.0..180.0).round(2) } # 30秒〜3分のランダムタイム
    note { "エントリータイム申告" }

    trait :fast_time do
      entry_time { rand(20.0..40.0).round(2) }
    end

    trait :slow_time do
      entry_time { rand(120.0..300.0).round(2) }
    end

    trait :sprint do
      association :style, factory: [:style, :freestyle_50]
      entry_time { rand(25.0..35.0).round(2) }
    end

    trait :distance do
      association :style, factory: [:style, :freestyle_1500]
      entry_time { rand(900.0..1200.0).round(2) }
    end
  end
end 