class AttendanceEvent < ApplicationRecord
  has_many :attendance, dependent: :destroy
  has_many :users, through: :attendance

  validates :title, presence: true
  validates :date, presence: true
end
