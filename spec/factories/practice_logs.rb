FactoryBot.define do
  factory :practice_log do
    association :attendance_event
    tags { ["クロール", "練習"] }
    style { %w[Fr Br Ba Fly IM].sample }
    rep_count { rand(1..10) }
    set_count { rand(1..5) }
    distance { rand(50..400) }
    circle { rand(0.0..100.0) }
    note { "練習ログの詳細" }

    trait :with_practice_times do
      after(:create) do |practice_log|
        create(:practice_time, practice_log: practice_log)
      end
    end

    trait :individual_medley do
      style { "IM" }
    end

    trait :short_distance do
      distance { rand(50..200) }
    end

    trait :long_distance do
      distance { rand(400..800) }
    end

    trait :freestyle do
      style { "Fr" }
    end

    trait :breaststroke do
      style { "Br" }
    end

    trait :backstroke do
      style { "Ba" }
    end

    trait :butterfly do
      style { "Fly" }
    end

    trait :style1 do
      style { "S1" }
    end

    trait :without_tags do
      tags { nil }
    end

    trait :without_note do
      note { nil }
    end

    trait :with_long_note do
      note { "a" * 1000 }
    end
  end
end
