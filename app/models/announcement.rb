class Announcement < ApplicationRecord
  validates :title, presence: true
  validates :content, presence: true
  validates :published_at, presence: true
  validate :published_at_must_be_future
  
  # デフォルトで有効なお知らせのみを取得
  scope :active, -> { where(is_active: true) }
  
  # 公開日時の降順で取得
  default_scope { order(published_at: :desc) }
  
  # 公開日時を設定するコールバック
  before_validation :set_published_at, on: :create
  
  private
  
  def set_published_at
    self.published_at ||= Time.current
  end
  
  def published_at_must_be_future
    if published_at.present? && published_at < Time.current
      errors.add(:published_at, "は現在日時以降を指定してください")
    end
  end
end 