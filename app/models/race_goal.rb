class RaceGoal < ApplicationRecord
  belongs_to :user
  belongs_to :attendance_event
  belongs_to :style
  has_one :race_review, dependent: :destroy
  has_many :race_feedbacks, dependent: :destroy

  validates :user_id, presence: true
  validates :attendance_event_id, presence: true
  validates :style_id, presence: true
  validates :time, presence: true, numericality: { greater_than: 0 }
  validates :note, presence: true
end
