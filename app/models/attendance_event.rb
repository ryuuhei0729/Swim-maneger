class AttendanceEvent < ApplicationRecord
  has_many :attendance, dependent: :destroy
  has_many :users, through: :attendance
  has_many :records, dependent: :destroy
  has_many :objectives, dependent: :destroy
  has_many :race_goals, dependent: :destroy

  validates :title, presence: true
  validates :date, presence: true
  validates :is_competition, inclusion: { in: [true, false] }

  scope :competitions, -> { where(is_competition: true) }
  scope :upcoming, -> { where('date >= ?', Date.current) }
  scope :past, -> { where('date < ?', Date.current) }
end
