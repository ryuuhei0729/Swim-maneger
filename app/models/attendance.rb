class Attendance < ApplicationRecord
  self.table_name = "attendance"

  belongs_to :user
  belongs_to :attendance_event

  enum :status, { present: "present", absent: "absent", other: "other" }

  validates :status, presence: true
  validates :user_id, presence: true
  validates :attendance_event_id, presence: true
  validates :user_id, uniqueness: { scope: :attendance_event_id }
  validate :note_required_for_absence_or_other

  private

  def note_required_for_absence_or_other
    if (absent? || other?) && note.blank?
      errors.add(:note, :required_for_absence_or_other)
    end
  end
end
