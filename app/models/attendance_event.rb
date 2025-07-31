class AttendanceEvent < Event
  # 練習、ミーティング、大会など出欠管理が必要なイベント
  has_one_attached :menu_image
  has_many :attendances, dependent: :destroy, foreign_key: 'attendance_event_id'
  has_many :users, through: :attendances
  has_many :practice_logs, dependent: :destroy, foreign_key: 'attendance_event_id'

  validates :menu_image, content_type: {
    in: %w[image/jpeg image/png application/pdf],
    message: "はJPEG、PNG、またはPDF形式でアップロードしてください"
  }, allow_blank: true

  enum :attendance_status, {
    before: 0,  # 出欠集計前
    open: 1,    # 受付中
    closed: 2   # 受付終了
  }, prefix: :attendance

  # デフォルト値設定（バリデーション前）
  before_validation :set_defaults
  
  private
  
  def set_defaults
    self.is_attendance = true unless is_attendance
    self.attendance_status = :before if attendance_status.nil?
  end
end
