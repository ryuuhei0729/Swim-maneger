class PracticeLog < ApplicationRecord
  belongs_to :attendance_event
  has_many :practice_times, dependent: :destroy

  validates :rep_count, :set_count, :distance, :circle, presence: true
  validates :rep_count, :set_count, :distance, numericality: { greater_than: 0 }
  validates :circle, numericality: { greater_than: 0 }
end 