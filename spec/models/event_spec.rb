require 'rails_helper'

RSpec.describe Event, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      event = Event.new(title: 'Test Event', date: Date.current)
      expect(event).to be_valid
    end

    it 'is not valid without a title' do
      event = Event.new(date: Date.current)
      expect(event).not_to be_valid
      expect(event.errors[:title]).to include("can't be blank")
    end

    it 'is not valid without a date' do
      event = Event.new(title: 'Test Event')
      expect(event).not_to be_valid
      expect(event.errors[:date]).to include("can't be blank")
    end
  end
end 