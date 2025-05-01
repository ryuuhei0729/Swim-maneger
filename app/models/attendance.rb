class Attendance < ApplicationRecord
  self.table_name = 'attendance'
  
  belongs_to :user
  belongs_to :attendance_event

  enum :status, { present: 'present', absent: 'absent', late: 'late' }

  validates :status, presence: true
  validates :user_id, uniqueness: { scope: :attendance_event_id }
  validate :note_required_for_absence_or_late

  private

  def note_required_for_absence_or_late
    if (absent? || late?) && note.blank?
      errors.add(:note, :required_for_absence_or_late)
    end
  end
end
