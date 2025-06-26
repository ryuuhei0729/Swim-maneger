FactoryBot.define do
  factory :announcement do
    sequence(:title) { |n| "お知らせ#{n}" }
    content { "お知らせの内容" }
    is_active { true }
    published_at { Time.current }

    trait :inactive do
      is_active { false }
    end

    trait :published do
      published_at { Time.current }
    end

    trait :unpublished do
      published_at { Time.current + 1.day }
    end

    trait :future do
      published_at { Time.current + 1.day }
    end

    trait :past do
      published_at { Time.current - 1.hour }
    end

    trait :without_content do
      content { nil }
    end

    trait :with_long_content do
      content { "a" * 1000 }
    end

    trait :with_short_content do
      content { "短いお知らせ内容です" }
    end
  end
end 