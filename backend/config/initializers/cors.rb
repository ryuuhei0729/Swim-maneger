Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # 本番環境では環境変数ALLOWED_ORIGINSで指定されたドメインのみを許可
    # 開発・テスト環境では全てのドメインを許可
    if Rails.env.production?
      # 環境変数ALLOWED_ORIGINSをカンマ区切りで読み取り、空白を除去
      allowed_origins = ENV.fetch('ALLOWED_ORIGINS', '').split(',').map(&:strip).reject(&:blank?)
      
      if allowed_origins.any?
        origins allowed_origins
        Rails.logger.info "CORS: 許可されたドメイン: #{allowed_origins.join(', ')}"
      else
        # 環境変数が設定されていない場合は警告を出力
        Rails.logger.warn "CORS: ALLOWED_ORIGINS環境変数が設定されていません。本番環境ではセキュリティ上の問題が発生する可能性があります。"
        origins '*'  # フォールバック（本番環境では推奨されない）
      end
    else
      # 開発・テスト環境では全てのドメインを許可
      origins '*'
      Rails.logger.debug "CORS: 開発・テスト環境 - 全てのドメインを許可"
    end

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: false,
      expose: ['Authorization']  # JWTトークンをFlutter側で取得可能にする
  end
end
