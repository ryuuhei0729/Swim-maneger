class RaceReview < ApplicationRecord
  belongs_to :race_goal
  belongs_to :style

  validates :race_goal_id, presence: true
  validates :style_id, presence: true
  validates :time, presence: true, numericality: { greater_than: 0 }
  validates :note, presence: true
end
