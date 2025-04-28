class Attendance < ApplicationRecord
  belongs_to :user
  belongs_to :attendance_event

  validates :status, presence: true
  validates :user_id, uniqueness: { scope: :attendance_event_id }
  validate :note_required_for_absence_or_late

  private

  def note_required_for_absence_or_late
    if (status == "欠席" || status == "遅刻") && note.blank?
      errors.add(:note, "を入力してください")
    end
  end
end
