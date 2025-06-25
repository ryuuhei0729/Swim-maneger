FactoryBot.define do
  factory :style do
    sequence(:name_jp) { |n| "種目#{n}" }
    sequence(:name) { |n| "Style#{n}" }
    style { %w[fr br ba fly im].sample }
    distance { [50, 100, 200, 400, 800].sample }

    trait :freestyle do
      style { "fr" }
      name_jp { "自由形" }
    end

    trait :breaststroke do
      style { "br" }
      name_jp { "平泳ぎ" }
    end

    trait :backstroke do
      style { "ba" }
      name_jp { "背泳ぎ" }
    end

    trait :butterfly do
      style { "fly" }
      name_jp { "バタフライ" }
    end

    trait :medley do
      style { "im" }
      name_jp { "個人メドレー" }
    end

    trait :distance_50 do
      distance { 50 }
    end

    trait :distance_100 do
      distance { 100 }
    end

    trait :distance_200 do
      distance { 200 }
    end

    trait :distance_400 do
      distance { 400 }
    end

    trait :distance_800 do
      distance { 800 }
    end
  end
end 