class Objective < ApplicationRecord
  belongs_to :user
  belongs_to :attendance_event
  belongs_to :style
  has_many :milestones, dependent: :destroy

  validates :target_time, presence: true, numericality: { greater_than: 0 }
  validates :quantity_note, presence: true
  validates :quality_title, presence: true
  validates :quality_note, presence: true
end
