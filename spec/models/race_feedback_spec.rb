require 'rails_helper'

RSpec.describe RaceFeedback, type: :model do
  describe 'バリデーション' do
    let(:race_feedback) { build(:race_feedback) }

    context '有効な属性の場合' do
      it '有効であること' do
        expect(race_feedback).to be_valid
      end
    end

    context 'noteが空の場合' do
      it '無効であること' do
        race_feedback.note = nil
        expect(race_feedback).not_to be_valid
        expect(race_feedback.errors[:note]).to include("を入力してください")
      end
    end

    context 'race_goal_idが空の場合' do
      it '無効であること' do
        race_feedback.race_goal_id = nil
        expect(race_feedback).not_to be_valid
        expect(race_feedback.errors[:race_goal]).to include("を入力してください")
      end
    end

    context 'user_idが空の場合' do
      it '無効であること' do
        race_feedback.user_id = nil
        expect(race_feedback).not_to be_valid
        expect(race_feedback.errors[:user]).to include("を入力してください")
      end
    end
  end

  describe 'アソシエーション' do
    it 'race_goalとの関連を持つこと' do
      race_feedback = create(:race_feedback)
      expect(race_feedback.race_goal).to be_present
    end

    it 'userとの関連を持つこと' do
      race_feedback = create(:race_feedback)
      expect(race_feedback.user).to be_present
    end
  end

  describe 'trait' do
    it 'with_long_note traitが正しく動作すること' do
      race_feedback = build(:race_feedback, :with_long_note)
      expect(race_feedback.note.length).to eq(1000)
    end

    it 'with_short_note traitが正しく動作すること' do
      race_feedback = build(:race_feedback, :with_short_note)
      expect(race_feedback.note.length).to be_between(10, 50)
    end
  end

  describe 'エッジケース' do
    it '非常に長いnoteを処理できること' do
      race_feedback = build(:race_feedback, note: "a" * 1000)
      expect(race_feedback).to be_valid
    end

    it '特殊文字を含むnoteを処理できること' do
      race_feedback = build(:race_feedback, note: "フィードバック：\n- スタートが良かった\n- ターンで改善の余地あり\n- 全体的に良いレースでした")
      expect(race_feedback).to be_valid
    end
  end
end 