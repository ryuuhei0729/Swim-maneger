class Record < ApplicationRecord
  belongs_to :user
  belongs_to :attendance_event, optional: true
  belongs_to :style
  has_many :split_times, dependent: :destroy

  validates :user_id, presence: true
  validates :style_id, presence: true
  validates :time, presence: true, numericality: { greater_than: 0 }
  validates :video_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }, allow_blank: true

  # キャッシュ無効化のコールバック（トランザクション確定後に実行）
  after_commit :invalidate_records_cache, on: [ :create, :update, :destroy ]

  private

  def invalidate_records_cache
    changes = previous_changes
    # 削除時は user_id のキャッシュを無条件で無効化
    if destroyed?
      CacheService.invalidate_records_cache(user_id) if user_id.present?
      return
    end

    # user_id の付け替え: 旧IDと新IDの両方で無効化
    if changes.key?('user_id')
      old_id, new_id = changes['user_id']
      [old_id, new_id].compact.uniq.each do |id|
        CacheService.invalidate_records_cache(id)
      end
      return
    end

    # time/style/note 変更時のみ現在の user_id を無効化
    if (changes.keys & %w[time style_id note]).any?
      CacheService.invalidate_records_cache(user_id) if user_id.present?
    end
  end
end
