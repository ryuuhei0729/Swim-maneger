class RaceReview < ApplicationRecord
  belongs_to :race_goal
  belongs_to :style

  validates :time, presence: true, numericality: { greater_than: 0 }
  validates :note, presence: true
end 