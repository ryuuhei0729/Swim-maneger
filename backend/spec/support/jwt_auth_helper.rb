module JwtAuthHelper
  def generate_jwt_token(user_auth)
    Rails.logger.debug "JWTトークン生成開始: user_auth_id=#{user_auth.id}, user_id=#{user_auth.user&.id}"
    
    begin
      # Devise JWTを使用してトークンを生成
      token = user_auth.generate_jwt
      Rails.logger.debug "JWTトークン生成成功: #{token[0..20]}..."
      token
    rescue => e
      Rails.logger.error "JWTトークン生成エラー: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    end
  end

  def auth_headers(user_auth)
    token = generate_jwt_token(user_auth)
    Rails.logger.debug "認証ヘッダー生成: Bearer #{token[0..20]}..."
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
end

RSpec.configure do |config|
  config.include JwtAuthHelper, type: :request
end
