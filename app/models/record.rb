class Record < ApplicationRecord
  belongs_to :user
  belongs_to :attendance_event, optional: true
  belongs_to :style
  has_many :split_times, dependent: :destroy

  validates :user_id, presence: true
  validates :style_id, presence: true
  validates :time, presence: true, numericality: { greater_than: 0 }
  validates :video_url, format: { with: URI.regexp(%w[http https]), allow_blank: true }
end
