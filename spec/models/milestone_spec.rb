require 'rails_helper'

RSpec.describe Milestone, type: :model do
  let(:objective) { create(:objective) }

  describe 'バリデーション' do
    let(:milestone) { build(:milestone, objective: objective) }

    context '有効な属性の場合' do
      it '有効であること' do
        expect(milestone).to be_valid
      end
    end

    context 'milestone_typeが空の場合' do
      it '無効であること' do
        milestone.milestone_type = nil
        expect(milestone).not_to be_valid
        expect(milestone.errors[:milestone_type]).to include("を入力してください")
      end
    end

    context 'milestone_typeが無効な値の場合' do
      it '無効であること' do
        milestone.milestone_type = "invalid"
        expect(milestone).not_to be_valid
        expect(milestone.errors[:milestone_type]).to include("は一覧にありません")
      end
    end

    context 'limit_dateが空の場合' do
      it '無効であること' do
        milestone.limit_date = nil
        expect(milestone).not_to be_valid
        expect(milestone.errors[:limit_date]).to include("を入力してください")
      end
    end

    context 'noteが空の場合' do
      it '無効であること' do
        milestone.note = nil
        expect(milestone).not_to be_valid
        expect(milestone.errors[:note]).to include("を入力してください")
      end
    end

    context 'objective_idが空の場合' do
      it '無効であること' do
        milestone_without_objective = build(:milestone, objective: nil)
        expect(milestone_without_objective).not_to be_valid
        expect(milestone_without_objective.errors[:objective]).to be_present
      end
    end
  end

  describe 'アソシエーション' do
    it 'objectiveとの関連を持つこと' do
      milestone = create(:milestone)
      expect(milestone.objective).to be_present
    end

    it 'milestone_reviewsとの関連を持つこと' do
      milestone = create(:milestone)
      milestone_review = create(:milestone_review, milestone: milestone)
      expect(milestone.milestone_reviews).to include(milestone_review)
    end
  end

  describe 'milestone_type バリデーション' do
    it 'quality が有効であること' do
      milestone = build(:milestone, objective: objective, milestone_type: "quality")
      expect(milestone).to be_valid
    end

    it 'quantity が有効であること' do
      milestone = build(:milestone, objective: objective, milestone_type: "quantity")
      expect(milestone).to be_valid
    end

    it '不正な値は無効であること' do
      milestone = build(:milestone, objective: objective, milestone_type: "invalid")
      expect(milestone).not_to be_valid
    end
  end

  describe 'trait' do
    it 'quality traitが正しく動作すること' do
      milestone = build(:milestone, :quality)
      expect(milestone.milestone_type).to eq("quality")
    end

    it 'quantity traitが正しく動作すること' do
      milestone = build(:milestone, :quantity)
      expect(milestone.milestone_type).to eq("quantity")
    end

    it 'with_reviews traitが正しく動作すること' do
      milestone = create(:milestone, :with_reviews)
      expect(milestone.milestone_reviews.count).to eq(1)
    end
  end

  describe 'エッジケース' do
    it '非常に長いnoteを処理できること' do
      milestone = build(:milestone, objective: objective, note: "a" * 1000)
      expect(milestone).to be_valid
    end

    it '特殊文字を含むnoteを処理できること' do
      milestone = build(:milestone, objective: objective, note: "マイルストーン：\n- 100m 1分以内達成\n- フォーム改善完了\n- 次の目標に向けて")
      expect(milestone).to be_valid
    end

    it '過去のlimit_dateを設定できること' do
      milestone = build(:milestone, objective: objective, limit_date: 1.day.ago)
      expect(milestone).to be_valid
    end

    it '未来のlimit_dateを設定できること' do
      milestone = build(:milestone, objective: objective, limit_date: 1.year.from_now)
      expect(milestone).to be_valid
    end
  end
end
