class Record < ApplicationRecord
  belongs_to :user
  belongs_to :attendance_event, optional: true
  belongs_to :style
  has_many :split_times, dependent: :destroy

  validates :user_id, presence: true
  validates :style_id, presence: true
  validates :time, presence: true, numericality: { greater_than: 0 }
  validates :video_url, format: { with: URI.regexp(%w[http https]), allow_blank: true }

  # キャッシュ無効化のコールバック（トランザクション確定後に実行）
  after_commit :invalidate_records_cache, on: [:create, :update, :destroy]

  private

  def invalidate_records_cache
    # 更新時は関連属性の変更時のみキャッシュ無効化を実行
    if destroyed? || saved_change_to_time? || saved_change_to_style_id? || saved_change_to_notes?
      CacheService.invalidate_records_cache(user_id)
    end
  end
end
