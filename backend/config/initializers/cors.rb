Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*'  # 本番環境では具体的なドメインを指定

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: false,
      expose: ['Authorization']  # JWTトークンをFlutter側で取得可能にする
  end
end
