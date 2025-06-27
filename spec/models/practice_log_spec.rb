require 'rails_helper'

RSpec.describe PracticeLog, type: :model do
  describe 'バリデーション' do
    let(:practice_log) { build(:practice_log) }

    context '有効な属性の場合' do
      it '有効であること' do
        expect(practice_log).to be_valid
      end
    end

    context 'attendance_event_idが空の場合' do
      it '無効であること' do
        practice_log.attendance_event_id = nil
        expect(practice_log).not_to be_valid
        expect(practice_log.errors[:attendance_event]).to include("を入力してください")
      end
    end

    context 'rep_countが空の場合' do
      it '無効であること' do
        practice_log.rep_count = nil
        expect(practice_log).not_to be_valid
        expect(practice_log.errors[:rep_count]).to include("を入力してください")
      end
    end

    context 'rep_countが0以下の場合' do
      it '無効であること' do
        practice_log.rep_count = 0
        expect(practice_log).not_to be_valid
        expect(practice_log.errors[:rep_count]).to include("は0より大きい値にしてください")
      end
    end

    context 'set_countが空の場合' do
      it '無効であること' do
        practice_log.set_count = nil
        expect(practice_log).not_to be_valid
        expect(practice_log.errors[:set_count]).to include("を入力してください")
      end
    end

    context 'set_countが0以下の場合' do
      it '無効であること' do
        practice_log.set_count = 0
        expect(practice_log).not_to be_valid
        expect(practice_log.errors[:set_count]).to include("は0より大きい値にしてください")
      end
    end

    context 'distanceが空の場合' do
      it '無効であること' do
        practice_log.distance = nil
        expect(practice_log).not_to be_valid
        expect(practice_log.errors[:distance]).to include("を入力してください")
      end
    end

    context 'distanceが0以下の場合' do
      it '無効であること' do
        practice_log.distance = 0
        expect(practice_log).not_to be_valid
        expect(practice_log.errors[:distance]).to include("は0より大きい値にしてください")
      end
    end

    context 'circleが空の場合' do
      it '無効であること' do
        practice_log.circle = nil
        expect(practice_log).not_to be_valid
        expect(practice_log.errors[:circle]).to include("を入力してください")
      end
    end

    context 'circleが負の値の場合' do
      it '無効であること' do
        practice_log.circle = -1
        expect(practice_log).not_to be_valid
        expect(practice_log.errors[:circle]).to include("は0以上の値にしてください")
      end
    end

    context 'styleが空の場合' do
      it '無効であること' do
        practice_log.style = nil
        expect(practice_log).not_to be_valid
        expect(practice_log.errors[:style]).to include("を入力してください")
      end
    end

    context 'styleが無効な値の場合' do
      it '無効であること' do
        expect { practice_log.style = "invalid" }.to raise_error(ArgumentError)
      end
    end
  end

  describe 'アソシエーション' do
    it 'attendance_eventとの関連を持つこと' do
      practice_log = create(:practice_log)
      expect(practice_log.attendance_event).to be_present
    end

    it 'practice_timesとの関連を持つこと' do
      practice_log = create(:practice_log)
      practice_time = create(:practice_time, practice_log: practice_log)
      expect(practice_log.practice_times).to include(practice_time)
    end
  end

  describe 'enum' do
    it '正しいstyle enum値を持つこと' do
      expect(PracticeLog.styles).to have_key("Fr")
      expect(PracticeLog.styles).to have_key("Br")
      expect(PracticeLog.styles).to have_key("Ba")
      expect(PracticeLog.styles).to have_key("Fly")
      expect(PracticeLog.styles).to have_key("IM")
      expect(PracticeLog.styles).to have_key("S1")
    end
  end

  describe 'trait' do
    it 'with_practice_times traitが正しく動作すること' do
      practice_log = create(:practice_log, :with_practice_times)
      expect(practice_log.practice_times.count).to eq(1)
    end

    it 'freestyle traitが正しく動作すること' do
      practice_log = build(:practice_log, :freestyle)
      expect(practice_log.style).to eq("Fr")
    end

    it 'backstroke traitが正しく動作すること' do
      practice_log = build(:practice_log, :backstroke)
      expect(practice_log.style).to eq("Ba")
    end

    it 'breaststroke traitが正しく動作すること' do
      practice_log = build(:practice_log, :breaststroke)
      expect(practice_log.style).to eq("Br")
    end

    it 'butterfly traitが正しく動作すること' do
      practice_log = build(:practice_log, :butterfly)
      expect(practice_log.style).to eq("Fly")
    end

    it 'individual_medley traitが正しく動作すること' do
      practice_log = build(:practice_log, :individual_medley)
      expect(practice_log.style).to eq("IM")
    end

    it 'short_distance traitが正しく動作すること' do
      practice_log = build(:practice_log, :short_distance)
      expect(practice_log.distance).to be_between(50, 200)
    end

    it 'long_distance traitが正しく動作すること' do
      practice_log = build(:practice_log, :long_distance)
      expect(practice_log.distance).to be_between(400, 800)
    end
  end

  describe 'エッジケース' do
    it 'circleが0の場合有効であること' do
      practice_log = build(:practice_log, circle: 0)
      expect(practice_log).to be_valid
    end

    it '非常に大きな数値を処理できること' do
      practice_log = build(:practice_log,
        rep_count: 999,
        set_count: 999,
        distance: 999999,
        circle: 999
      )
      expect(practice_log).to be_valid
    end
  end
end
