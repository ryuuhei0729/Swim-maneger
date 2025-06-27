require 'rails_helper'

RSpec.describe PracticeTime, type: :model do
  describe 'バリデーション' do
    let(:practice_time) { build(:practice_time) }

    context '有効な属性の場合' do
      it '有効であること' do
        expect(practice_time).to be_valid
      end
    end

    context 'rep_numberが空の場合' do
      it '無効であること' do
        practice_time.rep_number = nil
        expect(practice_time).not_to be_valid
        expect(practice_time.errors[:rep_number]).to include("を入力してください")
      end
    end

    context 'set_numberが空の場合' do
      it '無効であること' do
        practice_time.set_number = nil
        expect(practice_time).not_to be_valid
        expect(practice_time.errors[:set_number]).to include("を入力してください")
      end
    end

    context 'timeが空の場合' do
      it '無効であること' do
        practice_time.time = nil
        expect(practice_time).not_to be_valid
        expect(practice_time.errors[:time]).to include("を入力してください")
      end
    end

    context 'user_idが空の場合' do
      it '無効であること' do
        practice_time.user_id = nil
        expect(practice_time).not_to be_valid
        expect(practice_time.errors[:user]).to include("を入力してください")
      end
    end

    context 'practice_log_idが空の場合' do
      it '無効であること' do
        practice_time.practice_log_id = nil
        expect(practice_time).not_to be_valid
        expect(practice_time.errors[:practice_log]).to include("を入力してください")
      end
    end
  end

  describe 'アソシエーション' do
    it 'userとの関連を持つこと' do
      practice_time = create(:practice_time)
      expect(practice_time.user).to be_present
    end

    it 'practice_logとの関連を持つこと' do
      practice_time = create(:practice_time)
      expect(practice_time.practice_log).to be_present
    end
  end

  describe 'trait' do
    it 'fast_time traitが正しく動作すること' do
      practice_time = build(:practice_time, :fast_time)
      expect(practice_time.time).to be_between(20.0, 30.0)
    end

    it 'slow_time traitが正しく動作すること' do
      practice_time = build(:practice_time, :slow_time)
      expect(practice_time.time).to be_between(100.0, 120.0)
    end

    it 'first_rep traitが正しく動作すること' do
      practice_time = build(:practice_time, :first_rep)
      expect(practice_time.rep_number).to eq(1)
    end

    it 'last_rep traitが正しく動作すること' do
      practice_time = build(:practice_time, :last_rep)
      expect(practice_time.rep_number).to be_between(5, 10)
    end

    it 'first_set traitが正しく動作すること' do
      practice_time = build(:practice_time, :first_set)
      expect(practice_time.set_number).to eq(1)
    end

    it 'last_set traitが正しく動作すること' do
      practice_time = build(:practice_time, :last_set)
      expect(practice_time.set_number).to be_between(3, 5)
    end
  end

  describe 'エッジケース' do
    it '非常に大きな数値を処理できること' do
      practice_time = build(:practice_time,
        rep_number: 999,
        set_number: 999,
        time: 999999.99
      )
      expect(practice_time).to be_valid
    end

    it '小数点を含むtimeを処理できること' do
      practice_time = build(:practice_time, time: 25.67)
      expect(practice_time).to be_valid
    end
  end
end
