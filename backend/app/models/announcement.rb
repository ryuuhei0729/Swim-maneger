class Announcement < ApplicationRecord
  validates :title, presence: true
  validates :content, presence: true
  validates :published_at, presence: true
  validates :is_active, inclusion: { in: [ true, false ] }
  validate :published_at_must_be_future

  # デフォルトで有効なお知らせのみを取得
  scope :active, -> { where(is_active: true) }

  # 公開日時の降順で取得
  scope :published, -> { where("published_at <= ?", Time.current) }
  scope :recent, -> { order(published_at: :desc) }

  # 公開日時を設定するコールバック
  before_validation :set_published_at, on: :create

  # キャッシュ無効化のコールバック
  after_create :invalidate_announcements_cache
  after_update :invalidate_announcements_cache
  after_destroy :invalidate_announcements_cache

  private

  def set_published_at
    self.published_at ||= Time.current
  end

  def published_at_must_be_future
    if published_at.present? && published_at.beginning_of_minute < Time.current.beginning_of_minute
      errors.add(:published_at, "は現在日時以降を指定してください")
    end
  end

  def invalidate_announcements_cache
    CacheService.invalidate_announcements_cache
  end
end
