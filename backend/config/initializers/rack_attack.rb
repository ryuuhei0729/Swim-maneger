class Rack::Attack
  # キャッシュストアの設定
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  # APIレート制限
  throttle('api/ip', limit: 300, period: 5.minutes) do |req|
    req.ip if req.path.start_with?('/api/')
  end

  # ログイン試行制限
  throttle('login/ip', limit: 5, period: 20.seconds) do |req|
    req.ip if (req.path == '/user_auths/sign_in' || req.path == '/api/v1/auth/login') && req.post?
  end

  # 管理者APIレート制限
  throttle('admin_api/ip', limit: 100, period: 1.minute) do |req|
    req.ip if req.path.start_with?('/api/v1/admin/')
  end

  # ファイルアップロード制限
  throttle('upload/ip', limit: 10, period: 1.minute) do |req|
    req.ip if req.path.include?('upload') || req.path.include?('import')
  end

  # ブロックされたリクエストのレスポンス
  self.blocklisted_responder = lambda do |env|
    [429, {'Content-Type' => 'application/json'}, [{error: 'Too many requests. Please try again later.'}.to_json]]
  end

  # ログ出力
  ActiveSupport::Notifications.subscribe("rack.attack") do |name, start, finish, request_id, req|
    if req.env["rack.attack.match_type"] == :throttle
      Rails.logger.warn "Rack::Attack throttled request: #{req.ip} - #{req.path}"
    end
  end
end
