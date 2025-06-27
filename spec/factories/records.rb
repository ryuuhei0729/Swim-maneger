FactoryBot.define do
  factory :record do
    association :user
    association :style
    time { rand(20.0..120.0).round(2) }
    note { "記録の詳細" }
    video_url { "https://example.com/video.mp4" }
    association :attendance_event

    trait :without_video do
      video_url { nil }
    end

    trait :without_note do
      note { nil }
    end

    trait :without_attendance_event do
      attendance_event { nil }
    end

    trait :fast_time do
      time { rand(20.0..30.0).round(2) }
    end

    trait :slow_time do
      time { rand(100.0..120.0).round(2) }
    end
  end
end
