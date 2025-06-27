FactoryBot.define do
  factory :practice_log do
    association :attendance_event
    tags { [ "クロール", "練習" ] }
    style { "Fr" }
    rep_count { rand(1..10) }
    set_count { rand(1..5) }
    distance { rand(50..400) }
    circle { rand(20.0..60.0).round(2) }
    note { "練習ログの詳細" }

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

    trait :medley do
      style { "IM" }
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
