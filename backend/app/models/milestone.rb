class Milestone < ApplicationRecord
  belongs_to :objective
  has_many :milestone_reviews, dependent: :destroy

  validates :milestone_type, presence: true, inclusion: { in: [ "quality", "quantity" ] }
  validates :limit_date, presence: true
  validates :note, presence: true
end
