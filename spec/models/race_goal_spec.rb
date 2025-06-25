require 'rails_helper'

RSpec.describe RaceGoal, type: :model do
  describe 'バリデーション' do
    let(:race_goal) { build(:race_goal) }

    context '有効な属性の場合' do
      it '有効であること' do
        expect(race_goal).to be_valid
      end
    end

    context 'timeが空の場合' do
      it '無効であること' do
        race_goal.time = nil
        expect(race_goal).not_to be_valid
        expect(race_goal.errors[:time]).to include("を入力してください")
      end
    end

    context 'timeが0以下の場合' do
      it '無効であること' do
        race_goal.time = 0
        expect(race_goal).not_to be_valid
        expect(race_goal.errors[:time]).to include("は0より大きい値にしてください")
      end
    end

    context 'timeが負の値の場合' do
      it '無効であること' do
        race_goal.time = -1
        expect(race_goal).not_to be_valid
        expect(race_goal.errors[:time]).to include("は0より大きい値にしてください")
      end
    end

    context 'noteが空の場合' do
      it '無効であること' do
        race_goal.note = nil
        expect(race_goal).not_to be_valid
        expect(race_goal.errors[:note]).to include("を入力してください")
      end
    end

    context 'user_idが空の場合' do
      it '無効であること' do
        race_goal.user_id = nil
        expect(race_goal).not_to be_valid
        expect(race_goal.errors[:user]).to include("を入力してください")
      end
    end

    context 'attendance_event_idが空の場合' do
      it '無効であること' do
        race_goal.attendance_event_id = nil
        expect(race_goal).not_to be_valid
        expect(race_goal.errors[:attendance_event]).to include("を入力してください")
      end
    end

    context 'style_idが空の場合' do
      it '無効であること' do
        race_goal.style_id = nil
        expect(race_goal).not_to be_valid
        expect(race_goal.errors[:style]).to include("を入力してください")
      end
    end
  end

  describe 'アソシエーション' do
    it 'userとの関連を持つこと' do
      race_goal = create(:race_goal)
      expect(race_goal.user).to be_present
    end

    it 'attendance_eventとの関連を持つこと' do
      race_goal = create(:race_goal)
      expect(race_goal.attendance_event).to be_present
    end

    it 'styleとの関連を持つこと' do
      race_goal = create(:race_goal)
      expect(race_goal.style).to be_present
    end

    it 'race_reviewsとの関連を持つこと' do
      race_goal = create(:race_goal)
      race_review = create(:race_review, race_goal: race_goal)
      expect(race_goal.race_reviews).to include(race_review)
    end

    it 'race_feedbacksとの関連を持つこと' do
      race_goal = create(:race_goal)
      race_feedback = create(:race_feedback, race_goal: race_goal)
      expect(race_goal.race_feedbacks).to include(race_feedback)
    end
  end

  describe 'trait' do
    it 'with_reviews traitが正しく動作すること' do
      race_goal = create(:race_goal, :with_reviews)
      expect(race_goal.race_reviews.count).to eq(2)
    end

    it 'with_feedbacks traitが正しく動作すること' do
      race_goal = create(:race_goal, :with_feedbacks)
      expect(race_goal.race_feedbacks.count).to eq(2)
    end

    it 'fast_goal traitが正しく動作すること' do
      race_goal = build(:race_goal, :fast_goal)
      expect(race_goal.time).to be_between(20.0, 30.0)
    end

    it 'slow_goal traitが正しく動作すること' do
      race_goal = build(:race_goal, :slow_goal)
      expect(race_goal.time).to be_between(100.0, 120.0)
    end
  end

  describe 'エッジケース' do
    it '非常に大きなtimeを処理できること' do
      race_goal = build(:race_goal, time: 999999.99)
      expect(race_goal).to be_valid
    end

    it '非常に長いnoteを処理できること' do
      race_goal = build(:race_goal, note: "a" * 1000)
      expect(race_goal).to be_valid
    end

    it '特殊文字を含むnoteを処理できること' do
      race_goal = build(:race_goal, note: "目標：\n- 100m 1分以内\n- フォーム改善\n- スタートの精度向上")
      expect(race_goal).to be_valid
    end
  end
end 