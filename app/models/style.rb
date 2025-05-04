class Style < ApplicationRecord
  has_many :records, dependent: :destroy

  validates :name_jp, presence: true, uniqueness: true
  validates :name, presence: true, uniqueness: true
  validates :style, presence: true
  validates :distance, presence: true, numericality: { only_integer: true, greater_than: 0 }
end 