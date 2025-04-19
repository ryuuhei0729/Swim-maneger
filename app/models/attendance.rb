class Attendance < ApplicationRecord
  belongs_to :user
  belongs_to :attendance_event

  validates :status, presence: true
  validates :user_id, uniqueness: { scope: :attendance_event_id }
end
