class Style < ApplicationRecord
  has_many :records, dependent: :destroy
  has_many :objectives, dependent: :destroy
  has_many :race_goals, dependent: :destroy
  has_many :race_reviews, dependent: :destroy

  validates :name_jp, presence: true, uniqueness: true
  validates :name, presence: true, uniqueness: true
  validates :distance, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :style, presence: true

  # enum宣言（Rails 8.0対応）
  enum :style, {
    freestyle: 0,
    breaststroke: 1,
    backstroke: 2,
    butterfly: 3,
    individual_medley: 4
  }
end