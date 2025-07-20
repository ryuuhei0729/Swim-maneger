class Competition < AttendanceEvent
  # 大会特有の関連付け
  has_many :records, dependent: :destroy, foreign_key: 'attendance_event_id'
  has_many :objectives, dependent: :destroy, foreign_key: 'attendance_event_id'
  has_many :race_goals, dependent: :destroy, foreign_key: 'attendance_event_id'
  has_many :entries, dependent: :destroy, foreign_key: 'attendance_event_id'

  validates :is_competition, inclusion: { in: [true] } # 必ずtrue

  enum :entry_status, {
    before: 0,  # エントリー集計前
    open: 1,    # 集計中
    closed: 2   # 集計済み
  }, prefix: :entry

  # デフォルト値設定
  after_initialize :set_competition_defaults, if: :new_record?
  
  private
  
  def set_competition_defaults
    self.is_competition = true if is_competition.nil?
    self.entry_status = :before if entry_status.nil?
  end
end 