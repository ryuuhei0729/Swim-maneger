class Record < ApplicationRecord
  belongs_to :user
  belongs_to :attendance_event, optional: true
  belongs_to :style
  has_many :split_times, dependent: :destroy

  validates :user_id, presence: true
  validates :style_id, presence: true
  validates :time, presence: true, numericality: { greater_than: 0 }
  validates :video_url, format: { with: URI.regexp(%w[http https]), allow_blank: true }

  # キャッシュ無効化のコールバック
  after_create :invalidate_records_cache
  after_update :invalidate_records_cache
  after_destroy :invalidate_records_cache

  private

  def invalidate_records_cache
    CacheService.invalidate_records_cache(user_id)
  end
end
