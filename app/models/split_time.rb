class SplitTime < ApplicationRecord
  belongs_to :record
  belongs_to :race_goal

  validates :record_id, presence: true
  validates :race_goal_id, presence: true
  validates :distance, presence: true, numericality: { greater_than: 0 }
  validates :split_time, presence: true, numericality: { greater_than: 0 }
end 