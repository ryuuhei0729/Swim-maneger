class Style < ApplicationRecord
  has_many :records, dependent: :destroy
  has_many :objectives, dependent: :destroy
  has_many :race_goals, dependent: :destroy
  has_many :race_reviews, dependent: :destroy

  validates :name_jp, presence: true, uniqueness: true
  validates :name, presence: true, uniqueness: true
  validates :style, presence: true, inclusion: { in: ['fr', 'br', 'ba', 'fly', 'im'] }
  validates :distance, presence: true, numericality: { only_integer: true, greater_than: 0 }

  def self.styles
    ['fr', 'br', 'ba', 'fly', 'im']
  end
end 