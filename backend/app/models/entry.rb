class Entry < ApplicationRecord
  belongs_to :user
  belongs_to :attendance_event
  belongs_to :style

  # バリデーション強化
  validates :user_id, presence: true
  validates :attendance_event_id, presence: true
  validates :style_id, presence: true
  validates :entry_time, presence: true, 
            numericality: { 
              greater_than: 0, 
              less_than: 7200, # 2時間以下
              message: "エントリータイムは0秒より大きく2時間以下で入力してください" 
            }
  validates :user_id, uniqueness: { 
    scope: [:attendance_event_id, :style_id], 
    message: "同じ大会・種目に重複してエントリーできません" 
  }

  # カスタムバリデーション
  validate :entry_time_realistic_for_style
  validate :attendance_event_must_be_competition
  validate :user_must_be_player

  # スコープ拡張
  scope :by_user, ->(user) { where(user: user) }
  scope :by_event, ->(event) { where(attendance_event: event) }
  scope :by_event_id, ->(event_id) { where(attendance_event_id: event_id) }
  scope :by_style, ->(style) { where(style: style) }
  scope :by_competition, ->(competition) { joins(:attendance_event).where(events: { type: 'Competition' }) }
  scope :ordered_by_time, -> { order(:entry_time) }
  scope :recent, -> { order(created_at: :desc) }

  # フォーマット用メソッド
  def formatted_entry_time
    return "-" if entry_time.blank? || entry_time.zero?

    minutes = (entry_time / 60).floor
    remaining_seconds = (entry_time % 60).round(2)

    if minutes.zero?
      sprintf("%05.2f", remaining_seconds)
    else
      sprintf("%d:%05.2f", minutes, remaining_seconds)
    end
  end

  private

  def entry_time_realistic_for_style
    return unless entry_time.present? && style.present?
    
    # 種目別の現実的なタイム範囲をチェック
    min_time = case style.distance
               when 25 then 8    # 25m: 8秒以上
               when 50 then 15   # 50m: 15秒以上
               when 100 then 30  # 100m: 30秒以上
               when 200 then 60  # 200m: 1分以上
               else 10
               end

    if entry_time < min_time
      errors.add(:entry_time, "#{style.name_jp}の#{style.distance}mには短すぎるタイムです")
    end
  end

  def attendance_event_must_be_competition
    return unless attendance_event.present?
    
    unless attendance_event.is_competition?
      errors.add(:attendance_event, "は大会である必要があります")
    end
  end

  def user_must_be_player
    return unless user.present?
    
    unless user.player?
      errors.add(:user, "は選手である必要があります")
    end
  end


end 