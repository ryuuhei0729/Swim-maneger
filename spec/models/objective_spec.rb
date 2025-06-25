require 'rails_helper'

RSpec.describe Objective, type: :model do
  describe 'バリデーション' do
    let(:objective) { build(:objective) }

    context '有効な属性の場合' do
      it '有効であること' do
        expect(objective).to be_valid
      end
    end

    context 'target_timeが空の場合' do
      it '無効であること' do
        objective.target_time = nil
        expect(objective).not_to be_valid
        expect(objective.errors[:target_time]).to include("を入力してください")
      end
    end

    context 'target_timeが0以下の場合' do
      it '無効であること' do
        objective.target_time = 0
        expect(objective).not_to be_valid
        expect(objective.errors[:target_time]).to include("は0より大きい値にしてください")
      end
    end

    context 'target_timeが負の値の場合' do
      it '無効であること' do
        objective.target_time = -1
        expect(objective).not_to be_valid
        expect(objective.errors[:target_time]).to include("は0より大きい値にしてください")
      end
    end

    context 'quantity_noteが空の場合' do
      it '無効であること' do
        objective.quantity_note = nil
        expect(objective).not_to be_valid
        expect(objective.errors[:quantity_note]).to include("を入力してください")
      end
    end

    context 'quality_titleが空の場合' do
      it '無効であること' do
        objective.quality_title = nil
        expect(objective).not_to be_valid
        expect(objective.errors[:quality_title]).to include("を入力してください")
      end
    end

    context 'quality_noteが空の場合' do
      it '無効であること' do
        objective.quality_note = nil
        expect(objective).not_to be_valid
        expect(objective.errors[:quality_note]).to include("を入力してください")
      end
    end

    context 'user_idが空の場合' do
      it '無効であること' do
        objective.user_id = nil
        expect(objective).not_to be_valid
        expect(objective.errors[:user]).to include("を入力してください")
      end
    end

    context 'attendance_event_idが空の場合' do
      it '無効であること' do
        objective.attendance_event_id = nil
        expect(objective).not_to be_valid
        expect(objective.errors[:attendance_event]).to include("を入力してください")
      end
    end

    context 'style_idが空の場合' do
      it '無効であること' do
        objective.style_id = nil
        expect(objective).not_to be_valid
        expect(objective.errors[:style]).to include("を入力してください")
      end
    end
  end

  describe 'アソシエーション' do
    it 'userとの関連を持つこと' do
      objective = create(:objective)
      expect(objective.user).to be_present
    end

    it 'attendance_eventとの関連を持つこと' do
      objective = create(:objective)
      expect(objective.attendance_event).to be_present
    end

    it 'styleとの関連を持つこと' do
      objective = create(:objective)
      expect(objective.style).to be_present
    end

    it 'milestonesとの関連を持つこと' do
      objective = create(:objective)
      milestone = create(:milestone, objective: objective)
      expect(objective.milestones).to include(milestone)
    end
  end

  describe 'trait' do
    it 'with_milestones traitが正しく動作すること' do
      objective = create(:objective, :with_milestones)
      expect(objective.milestones.count).to eq(2)
    end

    it 'quality_milestone traitが正しく動作すること' do
      objective = create(:objective, :quality_milestone)
      expect(objective.milestones.count).to eq(1)
      expect(objective.milestones.first.milestone_type).to eq("quality")
    end

    it 'quantity_milestone traitが正しく動作すること' do
      objective = create(:objective, :quantity_milestone)
      expect(objective.milestones.count).to eq(1)
      expect(objective.milestones.first.milestone_type).to eq("quantity")
    end
  end

  describe 'エッジケース' do
    it '非常に大きなtarget_timeを処理できること' do
      objective = build(:objective, target_time: 999999.99)
      expect(objective).to be_valid
    end

    it '非常に長いnoteを処理できること' do
      objective = build(:objective, 
        quantity_note: "a" * 1000,
        quality_note: "b" * 1000
      )
      expect(objective).to be_valid
    end

    it '特殊文字を含むnoteを処理できること' do
      objective = build(:objective, 
        quantity_note: "目標：\n- 100m 1分以内\n- 200m 2分以内",
        quality_note: "フォーム改善：\n- ストロークの改善\n- ターンの精度向上"
      )
      expect(objective).to be_valid
    end
  end
end 