class AttendanceEvent < ApplicationRecord
  has_one_attached :menu_image
  has_many :attendance, dependent: :destroy
  has_many :users, through: :attendance
  has_many :records, dependent: :destroy
  has_many :objectives, dependent: :destroy
  has_many :race_goals, dependent: :destroy
  has_many :practice_logs, dependent: :destroy
  has_many :entries, dependent: :destroy

  validates :title, presence: true
  validates :date, presence: true
  validates :is_competition, inclusion: { in: [ true, false ] }
  validates :menu_image, content_type: {
    in: %w[image/jpeg image/png application/pdf],
    message: "はJPEG、PNG、またはPDF形式でアップロードしてください"
  }, allow_blank: true

  scope :competitions, -> { where(is_competition: true) }
  scope :upcoming, -> { where("date >= ?", Date.current) }
  scope :past, -> { where("date < ?", Date.current) }
  scope :future, -> { competitions.upcoming.order(:date) }
end
