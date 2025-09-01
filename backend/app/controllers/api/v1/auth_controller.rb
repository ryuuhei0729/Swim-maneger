class Api::V1::AuthController < Api::V1::BaseController
  skip_before_action :authenticate_api_user!, only: [:login]

  def login
    user_auth = UserAuth.find_by(email: params[:email])
    
    if user_auth&.valid_password?(params[:password])
      # Devise JWTの自動発行を使用（手動でJWTを生成しない）
      # レスポンスヘッダーからJWTトークンを取得
      jwt_token = request.env['warden-jwt_auth.token']
      
      render_success({
        token: jwt_token,
        user: {
          id: user_auth.user.id,
          name: user_auth.user.name,
          email: user_auth.email,
          user_type: user_auth.user.user_type,
          generation: user_auth.user.generation,
          profile_image_url: user_auth.profile_image_url
        }
      }, "ログインに成功しました")
    else
      render_error("メールアドレスまたはパスワードが間違っています", status: :unauthorized)
    end
  end

  def logout
    # Authorizationヘッダーの早期検証
    authorization_header = request.headers['Authorization']
    unless authorization_header.present?
      return render_error("認証ヘッダーが提供されていません", status: :bad_request)
    end

    # Bearerスキームの検証
    bearer_match = authorization_header.match(/^Bearer\s+(\S+)$/)
    unless bearer_match
      return render_error("不正な認証ヘッダー形式です", status: :bad_request)
    end

    jwt_token = bearer_match[1]
    
    begin
      # JWTトークンをデコードしてjtiを取得
      payload = Warden::JWTAuth::TokenDecoder.new.call(jwt_token)
      jti = payload['jti']
      exp = payload['exp']
      
      unless jti.present?
        return render_error("JWTトークンにjtiが含まれていません", status: :bad_request)
      end
      
      # 有効期限をTimeオブジェクトに変換
      expiration_time = exp.present? ? Time.at(exp) : nil
      
      # 既にdenylistに存在するかチェック
      if JwtDenylist.exists?(jti: jti)
        Rails.logger.info "JWTは既に無効化済み: jti=#{jti}"
        render_success({}, "ログアウトしました")
        return
      end
      
      # JwtDenylistにトークンを追加
      JwtDenylist.create!(jti: jti, exp: expiration_time)
      Rails.logger.info "JWT無効化成功: jti=#{jti}"
      
      render_success({}, "ログアウトしました")
      
    rescue JWT::DecodeError => e
      Rails.logger.warn "JWTデコードエラー: #{e.message}"
      render_error("無効なJWTトークンです", status: :bad_request)
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "JwtDenylist作成エラー: #{e.message}"
      render_error("トークンの無効化に失敗しました", status: :internal_server_error)
    rescue => e
      Rails.logger.error "JWTログアウトエラー: #{e.message}"
      render_error("ログアウト処理中にエラーが発生しました", status: :internal_server_error)
    end
  end
end 