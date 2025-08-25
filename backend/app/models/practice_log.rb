class PracticeLog < ApplicationRecord
  belongs_to :attendance_event
  has_many :practice_times, dependent: :destroy

  validates :attendance_event_id, presence: true
  validates :rep_count, presence: true, numericality: { greater_than: 0 }
  validates :set_count, presence: true, numericality: { greater_than: 0 }
  validates :distance, presence: true, numericality: { greater_than: 0 }
  validates :circle, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :style, presence: true, inclusion: { in: %w[Fr Br Ba Fly IM S1] }
  validates :note, length: { maximum: 1000 }

  # その日の参加者数を取得
  def attendees_count
    return @attendees_count if defined?(@attendees_count)
    
    @attendees_count = attendance_event.attendances
                   .includes(:user)
                   .where(status: ['present', 'other'])
                   .joins(:user)
                   .where(users: { user_type: 'player' })
                   .count
  end


  STYLE_OPTIONS = {
    "Fr" => "自由形",
    "Br" => "平泳ぎ",
    "Ba" => "背泳ぎ",
    "Fly" => "バタフライ",
    "IM" => "個人メドレー",
    "S1" => "Style 1"
  }.freeze
end
