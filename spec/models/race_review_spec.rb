require 'rails_helper'

RSpec.describe RaceReview, type: :model do
  let(:race_goal) { create(:race_goal) }
  let(:style) { create(:style) }

  describe 'バリデーション' do
    let(:race_review) { build(:race_review, race_goal: race_goal, style: style) }

    context '有効な属性の場合' do
      it '有効であること' do
        expect(race_review).to be_valid
      end
    end

    context 'timeが空の場合' do
      it '無効であること' do
        race_review.time = nil
        expect(race_review).not_to be_valid
        expect(race_review.errors[:time]).to include("を入力してください")
      end
    end

    context 'timeが0以下の場合' do
      it '無効であること' do
        race_review.time = 0
        expect(race_review).not_to be_valid
        expect(race_review.errors[:time]).to include("は0より大きい値にしてください")
      end
    end

    context 'timeが負の値の場合' do
      it '無効であること' do
        race_review.time = -1
        expect(race_review).not_to be_valid
        expect(race_review.errors[:time]).to include("は0より大きい値にしてください")
      end
    end

    context 'noteが空の場合' do
      it '無効であること' do
        race_review.note = nil
        expect(race_review).not_to be_valid
        expect(race_review.errors[:note]).to include("を入力してください")
      end
    end

    context 'race_goal_idが空の場合' do
      it '無効であること' do
        race_review_without_goal = build(:race_review, race_goal: nil, style: style)
        expect(race_review_without_goal).not_to be_valid
        expect(race_review_without_goal.errors[:race_goal]).to be_present
      end
    end

    context 'style_idが空の場合' do
      it '無効であること' do
        race_review_without_style = build(:race_review, race_goal: race_goal, style: nil)
        expect(race_review_without_style).not_to be_valid
        expect(race_review_without_style.errors[:style]).to be_present
      end
    end
  end

  describe 'アソシエーション' do
    it 'race_goalとの関連を持つこと' do
      race_review = create(:race_review)
      expect(race_review.race_goal).to be_present
    end

    it 'styleとの関連を持つこと' do
      race_review = create(:race_review)
      expect(race_review.style).to be_present
    end
  end

  describe 'trait' do
    it 'fast_time traitが正しく動作すること' do
      race_review = build(:race_review, :fast_time)
      expect(race_review.time).to be_between(20.0, 30.0)
    end

    it 'slow_time traitが正しく動作すること' do
      race_review = build(:race_review, :slow_time)
      expect(race_review.time).to be_between(100.0, 120.0)
    end

    it 'with_long_note traitが正しく動作すること' do
      race_review = build(:race_review, :with_long_note)
      expect(race_review.note.length).to eq(1000)
    end

    it 'with_short_note traitが正しく動作すること' do
      race_review = build(:race_review, :with_short_note)
      expect(race_review.note).to eq("短いレビューです。")
    end
  end

  describe 'エッジケース' do
    it '非常に大きなtimeを処理できること' do
      race_review = build(:race_review, race_goal: race_goal, style: style, time: 999999.99)
      expect(race_review).to be_valid
    end

    it '非常に長いnoteを処理できること' do
      race_review = build(:race_review, race_goal: race_goal, style: style, note: "a" * 1000)
      expect(race_review).to be_valid
    end

    it '特殊文字を含むnoteを処理できること' do
      race_review = build(:race_review, race_goal: race_goal, style: style, note: "レース振り返り：\n- スタートが良かった\n- ターンで時間をロス\n- 全体的に満足のいく結果")
      expect(race_review).to be_valid
    end
  end
end
