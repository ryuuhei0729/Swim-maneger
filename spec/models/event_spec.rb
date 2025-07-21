require 'rails_helper'

RSpec.describe Event, type: :model do
  describe 'バリデーション' do
    it '有効であること' do
      event = Event.new(title: 'Test Event', date: Date.current)
      expect(event).to be_valid
    end

    it 'titleが空の場合、無効であること' do
      event = Event.new(date: Date.current)
      expect(event).not_to be_valid
      expect(event.errors[:title]).to include("を入力してください")
    end

    it 'dateが空の場合、無効であること' do
      event = Event.new(title: 'Test Event')
      expect(event).not_to be_valid
      expect(event.errors[:date]).to include("を入力してください")
    end

    it 'typeが空の場合、無効であること' do
      event = Event.new(title: 'Test Event', date: Date.current, type: nil)
      expect(event).not_to be_valid
      expect(event.errors[:type]).to include("を入力してください")
    end
  end

  describe 'STI（Single Table Inheritance）' do
    it 'Eventクラスのデフォルトtypeは"Event"であること' do
      event = Event.create!(title: 'Test Event', date: Date.current)
      expect(event.type).to eq('Event')
    end

    it 'デフォルトのis_attendanceはfalseであること' do
      event = Event.create!(title: 'Test Event', date: Date.current)
      expect(event.is_attendance).to be false
    end

    it 'AttendanceEventとCompetitionは継承関係にあること' do
      expect(AttendanceEvent.superclass).to eq(Event)
      expect(Competition.superclass).to eq(AttendanceEvent)
    end
  end
end
