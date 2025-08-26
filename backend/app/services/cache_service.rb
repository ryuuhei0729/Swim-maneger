class CacheService
  include SanitizationHelper

  # キャッシュの有効期限（デフォルト）
  DEFAULT_EXPIRY = 1.hour

  # ユーザー情報のキャッシュ
  def self.cache_user_info(user_id, &block)
    raise ArgumentError, "Block is required" if block.nil?
    fetch_with_cache("user_info", [user_id], expires_in: 30.minutes, &block)
  end

  # ユーザー一覧のキャッシュ
  def self.cache_users_list(generation = nil, user_type = nil, &block)
    raise ArgumentError, "Block is required" if block.nil?
    fetch_with_cache("users_list", [generation, user_type], expires_in: 15.minutes, &block)
  end

  # イベント情報のキャッシュ
  def self.cache_events_list(date_range = nil, event_type = nil, &block)
    raise ArgumentError, "Block is required" if block.nil?
    fetch_with_cache("events_list", [date_range, event_type], expires_in: 10.minutes, &block)
  end

  # 出席状況のキャッシュ
  def self.cache_attendance_status(event_id, &block)
    raise ArgumentError, "Block is required" if block.nil?
    fetch_with_cache("attendance_status", [event_id], expires_in: 5.minutes, &block)
  end

  # 練習記録のキャッシュ
  def self.cache_practice_logs(user_id = nil, date_range = nil, &block)
    raise ArgumentError, "Block is required" if block.nil?
    fetch_with_cache("practice_logs", [user_id, date_range], expires_in: 10.minutes, &block)
  end

  # 記録のキャッシュ
  def self.cache_records(user_id = nil, style_id = nil, &block)
    raise ArgumentError, "Block is required" if block.nil?
    fetch_with_cache("records", [user_id, style_id], expires_in: 15.minutes, &block)
  end

  # 目標のキャッシュ
  def self.cache_objectives(user_id = nil, &block)
    raise ArgumentError, "Block is required" if block.nil?
    fetch_with_cache("objectives", [user_id], expires_in: 20.minutes, &block)
  end

  # お知らせのキャッシュ
  def self.cache_announcements(active_only = true, &block)
    raise ArgumentError, "Block is required" if block.nil?
    fetch_with_cache("announcements", [active_only], expires_in: 5.minutes, &block)
  end

  # 統計情報のキャッシュ
  def self.cache_statistics(stat_type, params = {}, &block)
    raise ArgumentError, "Block is required" if block.nil?
    fetch_with_cache("statistics", [stat_type, params], expires_in: 30.minutes, &block)
  end

  # 管理者ダッシュボードのキャッシュ
  def self.cache_admin_dashboard(&block)
    raise ArgumentError, "Block is required" if block.nil?
    fetch_with_cache("admin_dashboard", [], expires_in: 5.minutes, &block)
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
    # 記録キャッシュの無効化
    if user_id
      Rails.cache.delete_matched("records:#{user_id}:*")
    else
      Rails.cache.delete_matched("records:*")
    end
    
    # ユーザー詳細情報キャッシュの無効化
    if user_id
      Rails.cache.delete("user_info:#{user_id}")
    else
      Rails.cache.delete_matched("user_info:*")
    end
    
    # ユーザー一覧キャッシュの無効化（ベストタイムなどの情報が含まれるため）
    Rails.cache.delete_matched("users_list:*")
    
    # 統計情報キャッシュの無効化
    Rails.cache.delete_matched("statistics:*")
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
    # 後方互換: 旧キー "admin_dashboard:" も削除
    Rails.cache.delete("admin_dashboard")
    Rails.cache.delete("admin_dashboard:")
  end

  # 全キャッシュの削除（管理者用）
  def self.clear_all_cache
    Rails.cache.clear
  end

  # キャッシュ統計情報の取得
  def self.cache_stats
    if Rails.cache.respond_to?(:redis)
      {
        total_keys: Rails.cache.redis.dbsize,
        memory_usage: Rails.cache.redis.info['used_memory_human'],
        hit_rate: calculate_hit_rate
      }
    else
      {
        total_keys: nil,
        memory_usage: nil,
        hit_rate: nil,
        note: "Redis-specific statistics not available for this cache store"
      }
    end
  rescue => e
    Rails.logger.error "キャッシュ統計取得エラー: #{e.message}"
    { error: e.message }
  end

  private

  # 安定したキャッシュキーを構築し、Rails.cache.fetchを実行するヘルパー
  def self.fetch_with_cache(prefix, params, expires_in: DEFAULT_EXPIRY, &block)
    cache_key = build_stable_cache_key(prefix, params)
    Rails.cache.fetch(cache_key, expires_in: expires_in, &block)
  end

  # 安定したキャッシュキーを構築するヘルパー
  def self.build_stable_cache_key(prefix, params)
    # パラメータを安定した文字列に変換
    stable_params = Array(params).map { |param| serialize_param(param) }
    return prefix if stable_params.empty?
    "#{prefix}:#{stable_params.join(':')}"
  end

  # パラメータを安定した文字列にシリアライズするヘルパー
  def self.serialize_param(param)
    case param
    when nil
      "nil"
    when Range
      # Rangeを安定した形式でシリアライズ（inclusive/exclusiveを区別）
      begin_repr = serialize_param(param.begin)
      end_repr = serialize_param(param.end)
      exclusive = param.exclude_end? ? "true" : "false"
      "#{begin_repr}..#{end_repr}|exclusive:#{exclusive}"
    when Hash
      # ネストしたHashも含めて深いソートを実行
      deep_sort_hash(param).to_json
    when Array
      # 配列をJSON配列として安定した形式でシリアライズ
      param.map { |item| serialize_param(item) }.to_json
    when Date, DateTime, Time
      param.iso8601
    else
      # 非プリミティブオブジェクトの安定したシリアライズ
      serialize_object(param)
    end
  end

  # ネストしたHashを深くソートするヘルパー
  def self.deep_sort_hash(hash)
    sorted_hash = {}
    hash.keys.sort.each do |key|
      value = hash[key]
      sorted_hash[serialize_param(key)] = case value
      when Hash
        deep_sort_hash(value)
      when Array
        value.map { |item| item.is_a?(Hash) ? deep_sort_hash(item) : serialize_param(item) }
      else
        serialize_param(value)
      end
    end
    sorted_hash
  end

  # 非プリミティブオブジェクトの安定したシリアライズ
  def self.serialize_object(obj)
    if obj.respond_to?(:cache_key_with_version)
      obj.cache_key_with_version
    elsif obj.respond_to?(:cache_key)
      obj.cache_key
    elsif obj.respond_to?(:to_param)
      obj.to_param
    else
      # 最後の手段としてクラス名付きでJSONまたはinspect
      begin
        "#{obj.class.name}:#{obj.to_json}"
      rescue
        "#{obj.class.name}:#{obj.inspect}"
      end
    end
  end

  def self.calculate_hit_rate
    return nil unless Rails.cache.respond_to?(:redis)
    
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
