require 'rails_helper'

RSpec.describe MilestoneReview, type: :model do
  describe 'バリデーション' do
    let(:milestone_review) { build(:milestone_review) }

    context '有効な属性の場合' do
      it '有効であること' do
        expect(milestone_review).to be_valid
      end
    end

    context 'achievement_rateが空の場合' do
      it '無効であること' do
        milestone_review.achievement_rate = nil
        expect(milestone_review).not_to be_valid
        expect(milestone_review.errors[:achievement_rate]).to include("を入力してください")
      end
    end

    context 'achievement_rateが範囲外の場合' do
      it '0未満は無効であること' do
        milestone_review.achievement_rate = -1
        expect(milestone_review).not_to be_valid
        expect(milestone_review.errors[:achievement_rate]).to include("は0以上の値にしてください")
      end

      it '100を超える値は無効であること' do
        milestone_review.achievement_rate = 101
        expect(milestone_review).not_to be_valid
        expect(milestone_review.errors[:achievement_rate]).to include("は100以下の値にしてください")
      end
    end

    context 'negative_noteが空の場合' do
      it '無効であること' do
        milestone_review.negative_note = nil
        expect(milestone_review).not_to be_valid
        expect(milestone_review.errors[:negative_note]).to include("を入力してください")
      end
    end

    context 'positive_noteが空の場合' do
      it '無効であること' do
        milestone_review.positive_note = nil
        expect(milestone_review).not_to be_valid
        expect(milestone_review.errors[:positive_note]).to include("を入力してください")
      end
    end

    context 'milestone_idが空の場合' do
      it '無効であること' do
        milestone_review.milestone_id = nil
        expect(milestone_review).not_to be_valid
        expect(milestone_review.errors[:milestone]).to include("を入力してください")
      end
    end
  end

  describe 'アソシエーション' do
    it 'milestoneとの関連を持つこと' do
      milestone_review = create(:milestone_review)
      expect(milestone_review.milestone).to be_present
    end
  end

  describe 'trait' do
    it 'high_achievement traitが正しく動作すること' do
      milestone_review = build(:milestone_review, :high_achievement)
      expect(milestone_review.achievement_rate).to be_between(80, 100)
    end

    it 'low_achievement traitが正しく動作すること' do
      milestone_review = build(:milestone_review, :low_achievement)
      expect(milestone_review.achievement_rate).to be_between(0, 50)
    end

    it 'with_long_notes traitが正しく動作すること' do
      milestone_review = build(:milestone_review, :with_long_notes)
      expect(milestone_review.positive_note.length).to eq(1000)
      expect(milestone_review.negative_note.length).to eq(1000)
    end
  end

  describe 'エッジケース' do
    it 'achievement_rateが0の場合有効であること' do
      milestone_review = build(:milestone_review, achievement_rate: 0)
      expect(milestone_review).to be_valid
    end

    it 'achievement_rateが100の場合有効であること' do
      milestone_review = build(:milestone_review, achievement_rate: 100)
      expect(milestone_review).to be_valid
    end

    it '非常に長いnoteを処理できること' do
      milestone_review = build(:milestone_review,
        positive_note: "a" * 1000,
        negative_note: "b" * 1000
      )
      expect(milestone_review).to be_valid
    end

    it '特殊文字を含むnoteを処理できること' do
      milestone_review = build(:milestone_review,
        positive_note: "良い点：\n- フォームが改善された\n- タイムが向上した\n- 継続性が良くなった",
        negative_note: "改善点：\n- スタートが遅い\n- ターンで時間をロス\n- 持久力が不足"
      )
      expect(milestone_review).to be_valid
    end
  end
end
