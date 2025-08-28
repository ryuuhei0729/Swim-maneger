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

  # APIレスポンスキャッシュ（新規追加）
  def self.cache_api_response(endpoint, params = {}, expires_in: 10.minutes, &block)
    raise ArgumentError, "Block is required" if block.nil?
    normalized_params = normalize_filters(params)
    cache_key = "api_response:#{endpoint}:#{Digest::MD5.hexdigest(normalized_params)}"
    Rails.cache.fetch(cache_key, expires_in: expires_in, &block)
  end

  # 重いクエリのバックグラウンド処理用キャッシュ
  def self.cache_heavy_query(query_name, params = {}, expires_in: 1.hour, &block)
    raise ArgumentError, "Block is required" if block.nil?
    normalized_params = normalize_filters(params)
    cache_key = "heavy_query:#{query_name}:#{Digest::MD5.hexdigest(normalized_params)}"
    processing_key = "#{cache_key}:processing"
    
    # まず結果キャッシュをチェック
    if Rails.cache.exist?(cache_key)
      return Rails.cache.fetch(cache_key, expires_in: expires_in, &block)
    end
    
    # 処理中フラグをアトミックに設定（重複実行を防止）
    unless Rails.cache.write(processing_key, true, expires_in: 5.minutes, unless_exist: true)
      # 既に処理中の場合はデフォルト値を返す
      return yield if block_given?
      return nil
    end
    
    # バックグラウンドジョブで処理を実行
    HeavyQueryJob.perform_later(query_name, params, cache_key)
    
    # 処理中はデフォルト値を返す
    return yield if block_given?
    return nil
  end

  # 統計データの事前計算キャッシュ
  def self.cache_precomputed_stats(stat_type, date_range = nil, expires_in: 30.minutes, &block)
    raise ArgumentError, "Block is required" if block.nil?
    cache_key = "precomputed_stats:#{stat_type}:#{serialize_param(date_range)}"
    Rails.cache.fetch(cache_key, expires_in: expires_in, &block)
  end

  # ページネーション結果のキャッシュ
  def self.cache_paginated_results(resource, page, per_page, filters = {}, expires_in: 15.minutes, &block)
    raise ArgumentError, "Block is required" if block.nil?
    normalized_filters = normalize_filters(filters)
    cache_key = "paginated:#{resource}:#{page}:#{per_page}:#{Digest::MD5.hexdigest(normalized_filters)}"
    Rails.cache.fetch(cache_key, expires_in: expires_in, &block)
  end

  # 検索結果のキャッシュ
  def self.cache_search_results(query, filters = {}, expires_in: 10.minutes, &block)
    raise ArgumentError, "Block is required" if block.nil?
    normalized_filters = normalize_filters(filters)
    cache_key = "search:#{Digest::MD5.hexdigest(query)}:#{Digest::MD5.hexdigest(serialize_param(normalized_filters))}"
    Rails.cache.fetch(cache_key, expires_in: expires_in, &block)
  end

  # キャッシュの削除
  def self.invalidate_user_cache(user_id)
    Rails.cache.delete(build_stable_cache_key("user_info", user_id))
    Rails.cache.delete_matched("users_list:*")
    # APIレスポンスキャッシュも無効化
    Rails.cache.delete_matched("api_response:*")
  end

  def self.invalidate_events_cache
    Rails.cache.delete_matched("events_list:*")
    # 関連するAPIレスポンスキャッシュも無効化
    Rails.cache.delete_matched("api_response:calendar:*")
    Rails.cache.delete_matched("api_response:home:*")
  end

  def self.invalidate_attendance_cache(event_id = nil)
    if event_id
      Rails.cache.delete("attendance_status:#{event_id}")
    else
      Rails.cache.delete_matched("attendance_status:*")
    end
    # 関連するAPIレスポンスキャッシュも無効化
    Rails.cache.delete_matched("api_response:attendance:*")
  end

  def self.invalidate_practice_cache(user_id = nil)
    if user_id
      Rails.cache.delete_matched("practice_logs:#{serialize_param(user_id)}:*")
    else
      Rails.cache.delete_matched("practice_logs:*")
    end
    # 関連するAPIレスポンスキャッシュも無効化
    Rails.cache.delete_matched("api_response:practice:*")
  end

  def self.invalidate_records_cache(user_id = nil)
    if user_id
      Rails.cache.delete_matched("records:#{serialize_param(user_id)}:*")
    else
      Rails.cache.delete_matched("records:*")
    end
    # 関連するAPIレスポンスキャッシュも無効化
    Rails.cache.delete_matched("api_response:members:*")
    Rails.cache.delete_matched("api_response:home:*")
    Rails.cache.delete_matched("api_response:mypage:*")
  end

  def self.invalidate_objectives_cache(user_id = nil)
    if user_id
      Rails.cache.delete_matched("objectives:#{serialize_param(user_id)}:*")
    else
      Rails.cache.delete_matched("objectives:*")
    end
    # 関連するAPIレスポンスキャッシュも無効化
    Rails.cache.delete_matched("api_response:objectives:*")
  end

  def self.invalidate_announcements_cache
    Rails.cache.delete_matched("announcements:*")
    # 関連するAPIレスポンスキャッシュも無効化
    Rails.cache.delete_matched("api_response:home:*")
    Rails.cache.delete_matched("api_response:announcements:*")
  end

  def self.invalidate_statistics_cache(stat_type = nil)
    if stat_type
      serialized = serialize_param(stat_type)
      Rails.cache.delete_matched("statistics:#{serialized}:*")
      Rails.cache.delete_matched("precomputed_stats:#{serialized}:*")
    else
      Rails.cache.delete_matched("statistics:*")
      Rails.cache.delete_matched("precomputed_stats:*")
    end
  end

  def self.invalidate_admin_dashboard_cache
    Rails.cache.delete("admin_dashboard")
    Rails.cache.delete_matched("admin_dashboard:*")
    # 関連するAPIレスポンスキャッシュも無効化
    Rails.cache.delete_matched("api_response:admin/dashboard:*")
  end

  # 全キャッシュのクリア（開発・テスト用）
  def self.clear_all_cache
    Rails.cache.clear
    Rails.logger.info "全キャッシュをクリアしました"
  end

  # キャッシュ統計情報の取得
  def self.cache_stats
    if Rails.cache.respond_to?(:redis)
      {
        total_keys: Rails.cache.redis.dbsize,
        memory_usage: Rails.cache.redis.info['used_memory_human'],
        hit_rate: calculate_hit_rate,
        api_response_cache: count_cache_keys("api_response:*"),
        heavy_query_cache: count_cache_keys("heavy_query:*"),
        precomputed_stats_cache: count_cache_keys("precomputed_stats:*")
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

  # キャッシュキー数のカウント
  def self.count_cache_keys(pattern)
    return nil unless Rails.cache.respond_to?(:redis)
    
    # キャッシュネームスペースを検出
    namespace = detect_cache_namespace
    namespaced_pattern = namespace ? "#{namespace}:#{pattern}" : pattern
    
    # Redis接続を使用してSCANを実行
    Rails.cache.redis.with do |conn|
      conn.scan_each(match: namespaced_pattern).count
    end
  rescue => e
    Rails.logger.error "キャッシュキーカウントエラー: #{e.message}"
    nil
  end

  # キャッシュヒット率の計算
  def self.calculate_hit_rate
    return nil unless Rails.cache.respond_to?(:redis)
    
    Rails.cache.redis.with do |conn|
      info = conn.info
      hits = info['keyspace_hits'].to_i
      misses = info['keyspace_misses'].to_i
      total = hits + misses
      
      total > 0 ? (hits.to_f / total * 100).round(2) : 0
    end
  rescue => e
    Rails.logger.error "キャッシュヒット率計算エラー: #{e.message}"
    nil
  end

  # キャッシュの有効期限を延長
  def self.extend_cache_expiry(cache_key, additional_time = 1.hour)
    # まずtouchメソッドがサポートされているかチェック
    if Rails.cache.respond_to?(:touch)
      Rails.cache.touch(cache_key, expires_in: additional_time)
    else
      # touchがサポートされていない場合は、値を安全に再読み込みして再書き込み
      value = Rails.cache.read(cache_key)
      if value
        Rails.cache.write(cache_key, value, expires_in: additional_time)
      end
    end
  rescue => e
    Rails.logger.error "キャッシュ有効期限延長エラー: #{e.message}"
  end

  # キャッシュの優先度設定
  def self.set_cache_priority(cache_key, priority = :normal)
    return unless cache_key
    
    priority_expiry = case priority
                     when :high then 1.hour
                     when :normal then 30.minutes
                     when :low then 5.minutes
                     else 30.minutes
                     end
    
    extend_cache_expiry(cache_key, priority_expiry.to_i)
  rescue => e
    Rails.logger.error "キャッシュ優先度設定エラー: #{e.message}"
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

  # フィルターパラメータを正規化するヘルパー
  def self.normalize_filters(filters)
    # nilを空ハッシュに変換
    filters = {} if filters.nil?
    
    # 安定したソートで正規化されたJSONを生成
    canonical_json = canonicalize_hash(filters).to_json
    canonical_json
  end

  # ハッシュを正規化（安定したソート）
  def self.canonicalize_hash(obj)
    case obj
    when Hash
      # キーをソートして安定した順序を保証
      sorted_keys = obj.keys.sort_by(&:to_s)
      sorted_keys.each_with_object({}) do |key, result|
        result[key] = canonicalize_hash(obj[key])
      end
    when Array
      # 配列の各要素を正規化
      obj.map { |item| canonicalize_hash(item) }
    when String, Numeric, TrueClass, FalseClass, NilClass
      # プリミティブ型はそのまま返す
      obj
    else
      # その他の型は文字列に変換
      obj.to_s
    end
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
    hash.keys.sort_by(&:to_s).each do |key|
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

  # キャッシュネームスペースを検出するヘルパー
  def self.detect_cache_namespace
    cache_store = Rails.cache
    
    # Redis::Storeの場合
    if cache_store.respond_to?(:redis) && cache_store.redis.respond_to?(:namespace)
      return cache_store.redis.namespace
    end
    
    # ActiveSupport::Cache::RedisCacheStoreの場合
    if cache_store.respond_to?(:options) && cache_store.options[:namespace]
      return cache_store.options[:namespace]
    end
    
    # その他のRedisベースのキャッシュストア
    if cache_store.respond_to?(:redis) && cache_store.redis.respond_to?(:client)
      # Redisクライアントからネームスペースを取得を試行
      client = cache_store.redis.client
      if client.respond_to?(:namespace)
        return client.namespace
      end
    end
    
    # ネームスペースが見つからない場合はnilを返す
    nil
  rescue => e
    Rails.logger.warn "キャッシュネームスペース検出エラー: #{e.message}"
    nil
  end
end
