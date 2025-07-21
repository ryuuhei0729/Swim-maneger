FactoryBot.define do
  factory :competition do
    sequence(:title) { |n| "大会#{n}" }
    date { Date.current + rand(7..60).days } # 大会は通常1週間以上先
    place { "県立総合プール" }
    note { "大会の詳細情報" }
    type { 'Competition' }
    is_attendance { true }
    is_competition { true }
    attendance_status { 'before' }
    entry_status { 'before' }

    trait :future do
      date { Date.current + rand(7..60).days }
    end

    trait :past do
      date { Date.current - rand(7..60).days }
    end

    trait :today do
      date { Date.current }
    end

    trait :entry_open do
      entry_status { 'open' }
    end

    trait :entry_closed do
      entry_status { 'closed' }
    end

    trait :attendance_open do
      attendance_status { 'open' }
    end

    trait :attendance_closed do
      attendance_status { 'closed' }
    end

    trait :with_entries do
      after(:create) do |competition|
        create(:entry, attendance_event: competition)
      end
    end

    trait :with_records do
      after(:create) do |competition|
        create(:record, attendance_event: competition)
      end
    end

    trait :with_objectives do
      after(:create) do |competition|
        create(:objective, attendance_event: competition)
      end
    end

    trait :with_race_goals do
      after(:create) do |competition|
        create(:race_goal, attendance_event: competition)
      end
    end

    trait :with_attendance do
      after(:create) do |competition|
        create(:attendance, attendance_event: competition)
      end
    end
  end
end 