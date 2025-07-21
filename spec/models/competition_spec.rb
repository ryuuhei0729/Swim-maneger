require 'rails_helper'

RSpec.describe Competition, type: :model do
  describe 'バリデーション' do
    let(:competition) { build(:competition) }

    context '有効な属性の場合' do
      it '有効であること' do
        expect(competition).to be_valid
      end
    end

    it 'AttendanceEventから継承したバリデーションが動作すること' do
      competition.title = nil
      expect(competition).not_to be_valid
      expect(competition.errors[:title]).to include("を入力してください")
    end
  end

  describe 'STI（Single Table Inheritance）' do
    it 'Competitionのtypeは"Competition"であること' do
      competition = Competition.create!(title: 'Test Competition', date: Date.current)
      expect(competition.type).to eq('Competition')
    end

    it 'AttendanceEventから継承していること' do
      expect(Competition.superclass).to eq(AttendanceEvent)
    end

    it 'デフォルトのis_attendanceはtrueであること' do
      competition = Competition.create!(title: 'Test Competition', date: Date.current)
      expect(competition.is_attendance).to be true
    end

    it 'デフォルトのis_competitionはtrueであること' do
      competition = Competition.create!(title: 'Test Competition', date: Date.current)
      expect(competition.is_competition).to be true
    end

    it 'デフォルトのentry_statusは"before"であること' do
      competition = Competition.create!(title: 'Test Competition', date: Date.current)
      expect(competition.entry_status).to eq('before')
    end

    it 'デフォルトのattendance_statusは"before"であること' do
      competition = Competition.create!(title: 'Test Competition', date: Date.current)
      expect(competition.attendance_status).to eq('before')
    end
  end

  describe 'アソシエーション（Competition特有）' do
    let(:competition) { create(:competition) }

    it 'recordsとの関連を持つこと' do
      record = create(:record, attendance_event: competition)
      expect(competition.records).to include(record)
    end

    it 'objectivesとの関連を持つこと' do
      objective = create(:objective, attendance_event: competition)
      expect(competition.objectives).to include(objective)
    end

    it 'race_goalsとの関連を持つこと' do
      race_goal = create(:race_goal, attendance_event: competition)
      expect(competition.race_goals).to include(race_goal)
    end

    it 'entriesとの関連を持つこと' do
      entry = create(:entry, attendance_event: competition)
      expect(competition.entries).to include(entry)
    end
  end

  describe 'アソシエーション（AttendanceEventから継承）' do
    let(:competition) { create(:competition) }

    it 'attendancesとの関連を持つこと' do
      attendance = create(:attendance, attendance_event: competition)
      expect(competition.attendances).to include(attendance)
    end

    it 'usersとの関連を持つこと' do
      user = create(:user)
      create(:attendance, user: user, attendance_event: competition)
      expect(competition.users).to include(user)
    end
  end

  describe 'enum' do
    let(:competition) { create(:competition) }

    it 'entry_statusのenumが正しく動作すること' do
      expect(competition.entry_before?).to be true
      
      competition.entry_open!
      expect(competition.entry_open?).to be true
      
      competition.entry_closed!
      expect(competition.entry_closed?).to be true
    end

    it 'attendance_statusのenumが正しく動作すること（継承）' do
      expect(competition.attendance_before?).to be true
      
      competition.attendance_open!
      expect(competition.attendance_open?).to be true
      
      competition.attendance_closed!
      expect(competition.attendance_closed?).to be true
    end
  end
end 