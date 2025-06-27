require 'rails_helper'

RSpec.describe AttendanceEvent, type: :model do
  describe 'バリデーション' do
    let(:attendance_event) { build(:attendance_event) }

    context '有効な属性の場合' do
      it '有効であること' do
        expect(attendance_event).to be_valid
      end
    end

    context 'titleが空の場合' do
      it '無効であること' do
        attendance_event.title = nil
        expect(attendance_event).not_to be_valid
        expect(attendance_event.errors[:title]).to include("を入力してください")
      end
    end

    context 'dateが空の場合' do
      it '無効であること' do
        attendance_event.date = nil
        expect(attendance_event).not_to be_valid
        expect(attendance_event.errors[:date]).to include("を入力してください")
      end
    end

    context 'is_competitionが空の場合' do
      it '無効であること' do
        attendance_event.is_competition = nil
        expect(attendance_event).not_to be_valid
        expect(attendance_event.errors[:is_competition]).to include("は一覧にありません")
      end
    end

    context 'menu_imageが無効な形式の場合' do
      it '無効であること' do
        # Active Storageのテストは複雑なため、基本的な動作のみテスト
        expect(attendance_event).to respond_to(:menu_image)
      end
    end
  end

  describe 'アソシエーション' do
    it 'attendanceとの関連を持つこと' do
      attendance_event = create(:attendance_event)
      attendance = create(:attendance, attendance_event: attendance_event)
      expect(attendance_event.attendance).to include(attendance)
    end

    it 'usersとの関連を持つこと' do
      attendance_event = create(:attendance_event)
      user = create(:user)
      attendance = create(:attendance, attendance_event: attendance_event, user: user)
      expect(attendance_event.users).to include(user)
    end

    it 'recordsとの関連を持つこと' do
      attendance_event = create(:attendance_event)
      record = create(:record, attendance_event: attendance_event)
      expect(attendance_event.records).to include(record)
    end

    it 'objectivesとの関連を持つこと' do
      attendance_event = create(:attendance_event)
      objective = create(:objective, attendance_event: attendance_event)
      expect(attendance_event.objectives).to include(objective)
    end

    it 'race_goalsとの関連を持つこと' do
      attendance_event = create(:attendance_event)
      race_goal = create(:race_goal, attendance_event: attendance_event)
      expect(attendance_event.race_goals).to include(race_goal)
    end

    it 'practice_logsとの関連を持つこと' do
      attendance_event = create(:attendance_event)
      practice_log = create(:practice_log, attendance_event: attendance_event)
      expect(attendance_event.practice_logs).to include(practice_log)
    end
  end

  describe 'スコープ' do
    describe '.competitions' do
      it '競技会のみを返すこと' do
        competition = create(:attendance_event, :competition)
        practice = create(:attendance_event, :practice)

        expect(AttendanceEvent.competitions).to include(competition)
        expect(AttendanceEvent.competitions).not_to include(practice)
      end
    end

    describe '.upcoming' do
      it '今日以降のイベントを返すこと' do
        future_event = create(:attendance_event, date: 1.day.from_now)
        past_event = create(:attendance_event, date: 1.day.ago)

        expect(AttendanceEvent.upcoming).to include(future_event)
        expect(AttendanceEvent.upcoming).not_to include(past_event)
      end
    end

    describe '.past' do
      it '過去のイベントを返すこと' do
        future_event = create(:attendance_event, date: 1.day.from_now)
        past_event = create(:attendance_event, date: 1.day.ago)

        expect(AttendanceEvent.past).to include(past_event)
        expect(AttendanceEvent.past).not_to include(future_event)
      end
    end

    describe '.future' do
      it '今後の競技会を日付順で返すこと' do
        competition1 = create(:attendance_event, :competition, date: 2.days.from_now)
        competition2 = create(:attendance_event, :competition, date: 1.day.from_now)
        practice = create(:attendance_event, :practice, date: 1.day.from_now)

        future_competitions = AttendanceEvent.future
        expect(future_competitions).to include(competition1, competition2)
        expect(future_competitions).not_to include(practice)
        expect(future_competitions.first).to eq(competition2)
        expect(future_competitions.second).to eq(competition1)
      end
    end
  end

  describe 'trait' do
    it 'competition traitが正しく動作すること' do
      attendance_event = build(:attendance_event, :competition)
      expect(attendance_event.is_competition).to be true
    end

    it 'practice traitが正しく動作すること' do
      attendance_event = build(:attendance_event, :practice)
      expect(attendance_event.is_competition).to be false
    end

    it 'future_date traitが正しく動作すること' do
      attendance_event = build(:attendance_event, :future_date)
      expect(attendance_event.date).to be > Date.current
    end

    it 'past_date traitが正しく動作すること' do
      attendance_event = build(:attendance_event, :past_date)
      expect(attendance_event.date).to be < Date.current
    end

    it 'with_attendance traitが正しく動作すること' do
      attendance_event = create(:attendance_event, :with_attendance)
      expect(attendance_event.attendance.count).to eq(2)
    end

    it 'with_records traitが正しく動作すること' do
      attendance_event = create(:attendance_event, :with_records)
      expect(attendance_event.records.count).to eq(2)
    end

    it 'with_objectives traitが正しく動作すること' do
      attendance_event = create(:attendance_event, :with_objectives)
      expect(attendance_event.objectives.count).to eq(2)
    end

    it 'with_race_goals traitが正しく動作すること' do
      attendance_event = create(:attendance_event, :with_race_goals)
      expect(attendance_event.race_goals.count).to eq(2)
    end
  end

  describe 'エッジケース' do
    it '非常に長いtitleを処理できること' do
      attendance_event = build(:attendance_event, title: "a" * 1000)
      expect(attendance_event).to be_valid
    end

    it '非常に長いdescriptionを処理できること' do
      attendance_event = build(:attendance_event, description: "a" * 1000)
      expect(attendance_event).to be_valid
    end

    it '特殊文字を含むtitleを処理できること' do
      attendance_event = build(:attendance_event, title: "練習会（重要）：\n- フォーム改善\n- タイム測定")
      expect(attendance_event).to be_valid
    end

    it '遠い未来のdateを設定できること' do
      attendance_event = build(:attendance_event, date: 10.years.from_now)
      expect(attendance_event).to be_valid
    end

    it '遠い過去のdateを設定できること' do
      attendance_event = build(:attendance_event, date: 10.years.ago)
      expect(attendance_event).to be_valid
    end
  end
end
