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
  after_commit :invalidate_records_cache, on: [ :create, :update, :destroy ]

  private

  def invalidate_records_cache
    # 更新時は関連属性の変更時のみキャッシュ無効化を実行
    if destroyed? || saved_change_to_time? || saved_change_to_style_id? || saved_change_to_notes?
      # user_idが変更された場合、古いユーザーと新しいユーザーの両方のキャッシュを無効化
      if saved_change_to_user_id?
        previous_user_id = previous_changes[:user_id]&.first
        current_user_id = user_id

        # 古いユーザーのキャッシュを無効化（nilでない場合のみ）
        CacheService.invalidate_records_cache(previous_user_id) if previous_user_id.present?
        # 新しいユーザーのキャッシュを無効化（nilでない場合のみ）
        CacheService.invalidate_records_cache(current_user_id) if current_user_id.present?
      else
        # user_idが変更されていない場合は現在のユーザーのキャッシュのみ無効化
        CacheService.invalidate_records_cache(user_id)
      end
    end
  end
end
