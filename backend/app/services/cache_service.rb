class CacheService
  include SanitizationHelper

  # キャッシュの有効期限（デフォルト）
  DEFAULT_EXPIRY = 1.hour

  # ユーザー情報のキャッシュ
  def self.cache_user_info(user_id, &block)
    cache_key = "user_info:#{user_id}"
    Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
      block.call
    end
  end

  # ユーザー一覧のキャッシュ
  def self.cache_users_list(generation = nil, user_type = nil, &block)
    cache_key = "users_list:#{generation}:#{user_type}"
    Rails.cache.fetch(cache_key, expires_in: 15.minutes) do
      block.call
    end
  end

  # イベント情報のキャッシュ
  def self.cache_events_list(date_range = nil, event_type = nil, &block)
    cache_key = "events_list:#{date_range}:#{event_type}"
    Rails.cache.fetch(cache_key, expires_in: 10.minutes) do
      block.call
    end
  end

  # 出席状況のキャッシュ
  def self.cache_attendance_status(event_id, &block)
    cache_key = "attendance_status:#{event_id}"
    Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
      block.call
    end
  end

  # 練習記録のキャッシュ
  def self.cache_practice_logs(user_id = nil, date_range = nil, &block)
    cache_key = "practice_logs:#{user_id}:#{date_range}"
    Rails.cache.fetch(cache_key, expires_in: 10.minutes) do
      block.call
    end
  end

  # 記録のキャッシュ
  def self.cache_records(user_id = nil, style_id = nil, &block)
    cache_key = "records:#{user_id}:#{style_id}"
    Rails.cache.fetch(cache_key, expires_in: 15.minutes) do
      block.call
    end
  end

  # 目標のキャッシュ
  def self.cache_objectives(user_id = nil, &block)
    cache_key = "objectives:#{user_id}"
    Rails.cache.fetch(cache_key, expires_in: 20.minutes) do
      block.call
    end
  end

  # お知らせのキャッシュ
  def self.cache_announcements(active_only = true, &block)
    cache_key = "announcements:#{active_only}"
    Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
      block.call
    end
  end

  # 統計情報のキャッシュ
  def self.cache_statistics(stat_type, params = {}, &block)
    cache_key = "statistics:#{stat_type}:#{params.hash}"
    Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
      block.call
    end
  end

  # 管理者ダッシュボードのキャッシュ
  def self.cache_admin_dashboard(&block)
    cache_key = "admin_dashboard"
    Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
      block.call
    end
  end

  # キャッシュの削除
  def self.invalidate_user_cache(user_id)
    Rails.cache.delete("user_info:#{user_id}")
    Rails.cache.delete_matched("users_list:*")
  end

  def self.invalidate_events_cache
    Rails.cache.delete_matched("events_list:*")
  end

  def self.invalidate_attendance_cache(event_id = nil)
    if event_id
      Rails.cache.delete("attendance_status:#{event_id}")
    else
      Rails.cache.delete_matched("attendance_status:*")
    end
  end

  def self.invalidate_practice_cache(user_id = nil)
    if user_id
      Rails.cache.delete_matched("practice_logs:#{user_id}:*")
    else
      Rails.cache.delete_matched("practice_logs:*")
    end
  end

  def self.invalidate_records_cache(user_id = nil)
    if user_id
      Rails.cache.delete_matched("records:#{user_id}:*")
    else
      Rails.cache.delete_matched("records:*")
    end
  end

  def self.invalidate_objectives_cache(user_id = nil)
    if user_id
      Rails.cache.delete("objectives:#{user_id}")
    else
      Rails.cache.delete_matched("objectives:*")
    end
  end

  def self.invalidate_announcements_cache
    Rails.cache.delete_matched("announcements:*")
  end

  def self.invalidate_statistics_cache(stat_type = nil)
    if stat_type
      Rails.cache.delete_matched("statistics:#{stat_type}:*")
    else
      Rails.cache.delete_matched("statistics:*")
    end
  end

  def self.invalidate_admin_dashboard_cache
    Rails.cache.delete("admin_dashboard")
  end

  # 全キャッシュの削除（管理者用）
  def self.clear_all_cache
    Rails.cache.clear
  end

  # キャッシュ統計情報の取得
  def self.cache_stats
    {
      total_keys: Rails.cache.redis.dbsize,
      memory_usage: Rails.cache.redis.info['used_memory_human'],
      hit_rate: calculate_hit_rate
    }
  rescue => e
    Rails.logger.error "キャッシュ統計取得エラー: #{e.message}"
    { error: e.message }
  end

  private

  def self.calculate_hit_rate
    # RedisのINFOコマンドからヒット率を計算
    info = Rails.cache.redis.info
    hits = info['keyspace_hits'].to_i
    misses = info['keyspace_misses'].to_i
    total = hits + misses
    
    return 0 if total == 0
    (hits.to_f / total * 100).round(2)
  rescue => e
    Rails.logger.error "ヒット率計算エラー: #{e.message}"
    0
  end
end
