class Api::V1::BaseController < ApplicationController
  include SanitizationHelper
  
  # APIコントローラーではCSRF保護を無効化（JWT認証を使用するため）
  skip_forgery_protection

  before_action :authenticate_user_auth!
  before_action :log_api_request
  after_action :log_api_response
  around_action :measure_performance
  
  rescue_from StandardError, with: :handle_standard_error
  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :handle_validation_error
  rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing
  rescue_from "Pundit::NotAuthorizedError", with: :handle_unauthorized

  private

  def authenticate_user_auth!
    token = extract_token_from_header
    return render_unauthorized('認証トークンが提供されていません') unless token

    begin
      decoded_token = JWT.decode(token, Rails.application.credentials.secret_key_base, true, { algorithm: 'HS256' })
      user_id = decoded_token[0]['user_id']
      @current_user_auth = UserAuth.find(user_id)
      @current_user = @current_user_auth.user
    rescue JWT::DecodeError => e
      Rails.logger.error "JWTデコードエラー: #{e.message}"
      render_unauthorized('無効な認証トークンです')
    rescue ActiveRecord::RecordNotFound
      render_unauthorized('ユーザーが見つかりません')
    end
  end

  def extract_token_from_header
    header = request.headers['Authorization']
    header&.split(' ')&.last
  end

  def current_user_auth
    @current_user_auth
  end

  def current_user
    @current_user
  end

  def admin_user?
    current_user&.admin?
  end

  def require_admin!
    unless admin_user?
      Rails.logger.warn "管理者権限が必要なAPIにアクセス: #{current_user&.id} - #{request.path}"
      render_forbidden('管理者権限が必要です')
    end
  end

  def render_success(data = nil, message = '成功', status: :ok)
    response_data = {
      success: true,
      message: message,
      data: data,
      timestamp: Time.current.iso8601,
      request_id: request.request_id
    }
    
    render json: response_data, status: status
  end

  def render_error(message, status: :bad_request, errors: nil)
    response_data = {
      success: false, 
      message: message,
      errors: errors,
      timestamp: Time.current.iso8601,
      request_id: request.request_id
    }
    
    render json: response_data, status: status
  end

  def render_unauthorized(message = '認証が必要です')
    render_error(message, :unauthorized)
  end

  def render_forbidden(message = 'アクセス権限がありません')
    render_error(message, :forbidden)
  end

  def render_not_found(message = 'リソースが見つかりません')
    render_error(message, :not_found)
  end

  def render_validation_error(errors)
    render_error('バリデーションエラー', :unprocessable_entity, errors)
  end

  def handle_standard_error(exception)
    Rails.logger.error "API標準エラー: #{exception.class} - #{exception.message}"
    Rails.logger.error exception.backtrace.join("\n")
    
    # エラー監視とアラート設定
    notify_error(exception, 'standard_error')
    
    render_error('サーバー内部エラーが発生しました', :internal_server_error)
  end

  def handle_not_found(exception)
    Rails.logger.warn "API 404エラー: #{exception.message} - #{request.path}"
    render_not_found('リソースが見つかりません')
  end

  def handle_validation_error(exception)
    Rails.logger.warn "APIバリデーションエラー: #{exception.record.errors.full_messages.join(', ')}"
    render_validation_error(exception.record.errors.full_messages)
  end

  def handle_parameter_missing(exception)
    Rails.logger.warn "APIパラメータ不足: #{exception.message}"
    render_error("必須パラメータが不足しています: #{exception.param}", :bad_request)
  end

  def handle_unauthorized(exception)
    Rails.logger.warn "API認可エラー: #{exception.message} - ユーザー: #{current_user&.id}"
    render_forbidden('この操作を実行する権限がありません')
  end

  # API監視・ログ改善
  def log_api_request
    @request_start_time = Time.current
    @request_id = SecureRandom.uuid
    
    log_data = {
      request_id: @request_id,
      method: request.method,
      path: request.path,
      user_id: current_user&.id,
      user_type: current_user&.user_type,
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      params: sanitize_params(request.filtered_parameters),
      timestamp: @request_start_time.iso8601
    }
    
    Rails.logger.info "API Request: #{log_data.to_json}"
    
    # API使用統計の収集
    collect_api_usage_stats(log_data)
  end

  def log_api_response
    return unless @request_start_time
    
    duration = (Time.current - @request_start_time) * 1000 # ミリ秒
    
    log_data = {
      request_id: @request_id,
      method: request.method,
      path: request.path,
      status: response.status,
      duration_ms: duration.round(2),
      user_id: current_user&.id,
      timestamp: Time.current.iso8601
    }
    
    Rails.logger.info "API Response: #{log_data.to_json}"
    
    # パフォーマンスメトリクスの追加
    record_performance_metrics(log_data)
    
    # レスポンス時間が長い場合の警告
    if duration > 1000 # 1秒以上
      Rails.logger.warn "API遅延警告: #{request.path} - #{duration.round(2)}ms"
      notify_slow_response(request.path, duration)
    end
  end

  def measure_performance
    start_time = Time.current
    yield
    duration = (Time.current - start_time) * 1000
    
    # パフォーマンス監視
    if duration > 500 # 500ms以上
      Rails.logger.warn "パフォーマンス警告: #{controller_name}##{action_name} - #{duration.round(2)}ms"
    end
  end

  def collect_api_usage_stats(log_data)
    # Redisを使用してAPI使用統計を収集
    return unless Rails.cache.respond_to?(:redis)
    
    begin
      # エンドポイント別アクセス数
      endpoint_key = "api_stats:endpoint:#{log_data[:path]}"
      Rails.cache.redis.hincrby(endpoint_key, 'count', 1)
      Rails.cache.redis.expire(endpoint_key, 1.day)
      
      # ユーザータイプ別アクセス数
      user_type_key = "api_stats:user_type:#{log_data[:user_type]}"
      Rails.cache.redis.hincrby(user_type_key, 'count', 1)
      Rails.cache.redis.expire(user_type_key, 1.day)
      
      # 時間帯別アクセス数
      hour_key = "api_stats:hour:#{Time.current.hour}"
      Rails.cache.redis.hincrby(hour_key, 'count', 1)
      Rails.cache.redis.expire(hour_key, 1.day)
      
    rescue => e
      Rails.logger.error "API統計収集エラー: #{e.message}"
    end
  end

  def record_performance_metrics(log_data)
    # Redisを使用してパフォーマンスメトリクスを記録
    return unless Rails.cache.respond_to?(:redis)
    
    begin
      # エンドポイント別平均レスポンス時間
      endpoint_key = "api_performance:#{log_data[:path]}"
      Rails.cache.redis.hincrby(endpoint_key, 'total_time', log_data[:duration_ms].to_i)
      Rails.cache.redis.hincrby(endpoint_key, 'count', 1)
      Rails.cache.redis.expire(endpoint_key, 1.day)
      
      # レスポンス時間の分布
      duration_bucket = case log_data[:duration_ms]
                       when 0..100 then '0-100ms'
                       when 100..500 then '100-500ms'
                       when 500..1000 then '500-1000ms'
                       else '1000ms+'
                       end
      
      bucket_key = "api_performance:buckets:#{duration_bucket}"
      Rails.cache.redis.hincrby(bucket_key, 'count', 1)
      Rails.cache.redis.expire(bucket_key, 1.day)
      
    rescue => e
      Rails.logger.error "パフォーマンスメトリクス記録エラー: #{e.message}"
    end
  end

  def notify_error(exception, error_type)
    # エラー監視とアラート設定
    error_data = {
      type: error_type,
      message: exception.message,
      class: exception.class.name,
      path: request.path,
      user_id: current_user&.id,
      timestamp: Time.current.iso8601,
      backtrace: exception.backtrace&.first(5)
    }
    
    Rails.logger.error "API Error Alert: #{error_data.to_json}"
    
    # 本番環境では外部監視サービスに通知
    if Rails.env.production?
      # Slack通知やメール通知などの実装
      # notify_external_monitoring_service(error_data)
    end
  end

  def notify_slow_response(path, duration)
    # 遅いレスポンスの通知
    slow_response_data = {
      path: path,
      duration_ms: duration,
      user_id: current_user&.id,
      timestamp: Time.current.iso8601
    }
    
    Rails.logger.warn "Slow Response Alert: #{slow_response_data.to_json}"
    
    # 本番環境では外部監視サービスに通知
    if Rails.env.production?
      # notify_external_monitoring_service(slow_response_data)
    end
  end

  def sanitize_params(params)
    # 機密情報を再帰的に除去
    recursive_sanitize(params)
  end

  def recursive_sanitize(obj)
    case obj
    when Hash
      obj.each_with_object({}) do |(key, value), sanitized|
        # 機密キーかどうかをチェック（文字列・シンボル両方に対応）
        key_str = key.to_s.downcase
        unless sensitive_key?(key_str)
          sanitized[key] = recursive_sanitize(value)
        end
      end
    when Array
      obj.map { |item| recursive_sanitize(item) }
    else
      obj
    end
  end

  def sensitive_key?(key_str)
    sensitive_keys = %w[password password_confirmation token secret api_key access_token]
    sensitive_keys.any? { |sensitive| key_str.include?(sensitive) }
  end

  # API統計情報の取得
  def self.get_api_stats
    return {} unless Rails.cache.respond_to?(:redis)
    
    begin
      {
        popular_endpoints: get_popular_endpoints,
        user_type_distribution: get_user_type_distribution,
        hourly_activity: get_hourly_activity,
        performance_metrics: get_performance_metrics
      }
    rescue => e
      Rails.logger.error "API統計取得エラー: #{e.message}"
      {}
    end
  end

  def self.get_popular_endpoints
    return [] unless Rails.cache.respond_to?(:redis)
    
    keys = Rails.cache.redis.keys("api_stats:endpoint:*")
    keys.map do |key|
      path = key.split(':').last
      count = Rails.cache.redis.hget(key, 'count').to_i
      { path: path, count: count }
    end.sort_by { |item| -item[:count] }.first(10)
  end

  def self.get_user_type_distribution
    return [] unless Rails.cache.respond_to?(:redis)
    
    keys = Rails.cache.redis.keys("api_stats:user_type:*")
    keys.map do |key|
      user_type = key.split(':').last
      count = Rails.cache.redis.hget(key, 'count').to_i
      { user_type: user_type, count: count }
    end.sort_by { |item| -item[:count] }
  end

  def self.get_hourly_activity
    return [] unless Rails.cache.respond_to?(:redis)
    
    (0..23).map do |hour|
      key = "api_stats:hour:#{hour}"
      count = Rails.cache.redis.hget(key, 'count').to_i
      { hour: hour, count: count }
    end
  end

  def self.get_performance_metrics
    return {} unless Rails.cache.respond_to?(:redis)
    
    keys = Rails.cache.redis.keys("api_performance:*")
    metrics = {}
    
    keys.each do |key|
      if key.include?(':buckets:')
        bucket = key.split(':').last
        count = Rails.cache.redis.hget(key, 'count').to_i
        metrics[bucket] = count
      else
        path = key.split(':').last
        total_time = Rails.cache.redis.hget(key, 'total_time').to_i
        count = Rails.cache.redis.hget(key, 'count').to_i
        avg_time = count > 0 ? (total_time.to_f / count).round(2) : 0
        metrics[path] = { avg_time: avg_time, count: count }
      end
    end
    
    metrics
  end
end 