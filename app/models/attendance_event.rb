class AttendanceEvent < ApplicationRecord
  has_many :attendance, dependent: :destroy
  has_many :users, through: :attendance
  has_many :records, dependent: :destroy

  validates :title, presence: true
  validates :date, presence: true
end
