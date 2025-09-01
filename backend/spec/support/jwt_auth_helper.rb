module JwtAuthHelper
  def generate_jwt_token(user_auth)
    Rails.logger.debug "JWTトークン生成開始: user_auth_id=#{user_auth.id}, user_id=#{user_auth.user&.id}"
    
    begin
      # Devise JWTを使用してトークンを生成
      token = user_auth.generate_jwt
      jti = extract_jti_from_token(token)
      Rails.logger.debug "JWTトークン生成成功: jti=#{jti}"
      token
    rescue => e
      Rails.logger.error "JWTトークン生成エラー: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    end
  end

  def auth_headers(user_auth)
    token = generate_jwt_token(user_auth)
    # トークンからjtiを直接抽出してログに出力（トークン自体はログしない）
    jti = JWT.decode(token, nil, false)[0]['jti']
    Rails.logger.debug "認証ヘッダー生成: jti=#{jti}"
    { 'Authorization' => "Bearer #{token}" }
  rescue => e
    Rails.logger.warn "JWTトークンからjti抽出失敗: #{e.message}"
    Rails.logger.debug "認証ヘッダー生成: jti=unknown"
    { 'Authorization' => "Bearer #{token}" }
  end

  def admin_auth_headers
    admin_user_auth = create(:user_auth, user: create(:user, user_type: :coach))
    auth_headers(admin_user_auth)
  end

  def player_auth_headers
    player_user_auth = create(:user_auth, user: create(:user, user_type: :player))
    auth_headers(player_user_auth)
  end

  # Devise JWTを使用したトークン検証メソッド
  def decode_jwt_token(token)
    Warden::JWTAuth::TokenDecoder.new.call(token)
  end

  private

  # JWTトークンからjtiを抽出（検証なしでデコード）
  def extract_jti_from_token(token)
    begin
      # 検証なしでペイロードを取得（テストヘルパー用）
      payload = JWT.decode(token, nil, false)[0]
      payload['jti']
    rescue => e
      Rails.logger.warn "JWTトークンからjti抽出失敗: #{e.message}"
      'unknown_jti'
    end
  end
end

RSpec.configure do |config|
  # 認証関連のヘルパーを全てのテストタイプで利用可能にする
  config.include JwtAuthHelper, type: :request
  config.include JwtAuthHelper, type: :controller
  config.include JwtAuthHelper, type: :model
  config.include JwtAuthHelper, type: :system
end
