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
  end
end
