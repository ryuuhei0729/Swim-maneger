class Entry < ApplicationRecord
  belongs_to :user
  belongs_to :attendance_event
  belongs_to :style

  validates :user_id, presence: true
  validates :attendance_event_id, presence: true
  validates :style_id, presence: true
  validates :entry_time, presence: true, numericality: { greater_than: 0 }
  validates :user_id, uniqueness: { scope: [:attendance_event_id, :style_id], 
                                    message: "同じ大会・種目に重複してエントリーできません" }

  scope :by_user, ->(user) { where(user: user) }
  scope :by_event, ->(event) { where(attendance_event: event) }
  scope :by_style, ->(style) { where(style: style) }

  def formatted_entry_time
    return "" if entry_time.blank?
    
    minutes = (entry_time / 60).to_i
    seconds = (entry_time % 60)
    
    if minutes > 0
      format("%d:%05.2f", minutes, seconds)
    else
      format("%.2f", seconds)
    end
  end
end 