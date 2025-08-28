class Attendance < ApplicationRecord
  belongs_to :user
  belongs_to :attendance_event

  validates :status, presence: true
  validates :user_id, presence: true
  validates :attendance_event_id, presence: true
  validates :user_id, uniqueness: { scope: :attendance_event_id }
  validate :note_required_for_absence_or_other

  # enum宣言（Rails 8.0対応）
  enum :status, {
    present: 0,
    absent: 1,
    other: 2
  }

  private

  def note_required_for_absence_or_other
    if status.present? && (absent? || other?) && note.blank?
      errors.add(:note, :required_for_absence_or_other)
    end
  end
end
