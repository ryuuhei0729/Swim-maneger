class Event < ApplicationRecord
  validates :title, presence: true
  validates :date, presence: true
  validates :type, presence: true
end
