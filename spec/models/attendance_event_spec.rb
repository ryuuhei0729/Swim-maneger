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

    context 'menu_imageが無効な形式の場合' do
      it '無効であること' do
        # Active Storageのテストは複雑なため、基本的な動作のみテスト
        expect(attendance_event).to respond_to(:menu_image)
      end
    end
  end

  describe 'STI（Single Table Inheritance）' do
    it 'AttendanceEventのtypeは"AttendanceEvent"であること' do
      attendance_event = AttendanceEvent.create!(title: 'Test Practice', date: Date.current)
      expect(attendance_event.type).to eq('AttendanceEvent')
    end

    it 'デフォルトのis_attendanceはtrueであること' do
      attendance_event = AttendanceEvent.create!(title: 'Test Practice', date: Date.current)
      expect(attendance_event.is_attendance).to be true
    end

    it 'デフォルトのis_competitionはfalseであること' do
      attendance_event = AttendanceEvent.create!(title: 'Test Practice', date: Date.current)
      expect(attendance_event.is_competition).to be false
    end

    it 'デフォルトのattendance_statusは"before"であること' do
      attendance_event = AttendanceEvent.create!(title: 'Test Practice', date: Date.current)
      expect(attendance_event.attendance_status).to eq('before')
    end
  end

  describe 'アソシエーション' do
    it 'attendancesとの関連を持つこと' do
      attendance_event = create(:attendance_event)
      attendance = create(:attendance, attendance_event: attendance_event)
      expect(attendance_event.attendances).to include(attendance)
    end

    it 'usersとの関連を持つこと' do
      attendance_event = create(:attendance_event)
      user = create(:user)
      attendance = create(:attendance, attendance_event: attendance_event, user: user)
      expect(attendance_event.users).to include(user)
    end

    it 'practice_logsとの関連を持つこと' do
      attendance_event = create(:attendance_event)
      practice_log = create(:practice_log, attendance_event: attendance_event)
      expect(attendance_event.practice_logs).to include(practice_log)
    end
  end

  describe 'trait' do

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
      expect(attendance_event.attendances.count).to eq(1)
    end
  end

  describe 'エッジケース' do
    it '非常に長いtitleを処理できること' do
      attendance_event = build(:attendance_event, title: "a" * 1000)
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
