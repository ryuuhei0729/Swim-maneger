class MilestoneReview < ApplicationRecord
  belongs_to :milestone

  validates :achievement_rate, presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :negative_note, presence: true
  validates :positive_note, presence: true
end
