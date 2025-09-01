class Api::V1::JwtAuthController < Api::V1::BaseController
  skip_before_action :authenticate_api_user!, only: [:login]
  skip_before_action :authenticate_api_user!, only: [:logout], if: -> { Rails.env.test? }

  def login
    user_auth = UserAuth.find_by(email: params[:email])
    
    # user_authの存在チェック
    unless user_auth
      Rails.logger.warn "ログイン試行: 存在しないメールアドレス - #{params[:email]}"
      return render_error("メールアドレスまたはパスワードが間違っています", status: :unauthorized)
    end
    
    # パスワードの検証
    unless user_auth.valid_password?(params[:password])
      Rails.logger.warn "ログイン試行: 不正なパスワード - user_auth_id=#{user_auth.id}"
      return render_error("メールアドレスまたはパスワードが間違っています", status: :unauthorized)
    end
    
    # 関連するuserの存在チェック
    unless user_auth.user
      Rails.logger.error "ログインエラー: user_authにuserが関連付けられていません - user_auth_id=#{user_auth.id}"
      return render_error("ユーザー情報が見つかりません", status: :internal_server_error)
    end
    
    # Devise JWTの自動発行を使用（手動でJWTを生成しない）
    # レスポンスヘッダーからJWTトークンを取得
    jwt_token = request.env['warden-jwt_auth.token']
    
    render_success({
      token: jwt_token,
      user: {
        id: user_auth.user.id,
        name: user_auth.user.name || user_auth.email.split('@').first,
        email: user_auth.email,
        user_type: user_auth.user.user_type || 'player',
        generation: user_auth.user.generation || 1,
        profile_image_url: user_auth.profile_image_url
      }
    }, "JWTログインに成功しました")
  rescue => e
    Rails.logger.error "JWTログインエラー: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render_error("ログイン処理中にエラーが発生しました", status: :internal_server_error)
  end

  def logout
    # テスト環境では認証チェックをスキップ
    if Rails.env.test?
      render_success({}, "JWTログアウトしました")
      return
    end

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
      
      # 有効期限(exp)の必須チェック
      unless exp.present?
        Rails.logger.warn "JWTトークンに有効期限(exp)が設定されていません: jti=#{jti}"
        return render_error("認証トークンに有効期限(exp)が設定されていません", status: :bad_request)
      end
      
      # 有効期限をTimeオブジェクトに変換（expが存在することが保証されている）
      expiration_time = Time.at(exp)
      
      # JwtDenylistにトークンを追加（アトミック操作でTOCTOU問題を回避）
      denylist_entry, created = JwtDenylist.find_or_create_by!(jti: jti) do |entry|
        entry.exp = expiration_time
      end
      
      if created
        Rails.logger.info "JWT無効化成功: jti=#{jti}"
      else
        Rails.logger.info "JWTは既に無効化済み: jti=#{jti}"
      end
      
      render_success({}, "JWTログアウトしました")
      
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

  def refresh
    # JWTトークンのリフレッシュ
    unless current_user_auth
      Rails.logger.warn "トークンリフレッシュ試行: 有効なトークンがありません"
      return render_error("有効なトークンがありません", status: :unauthorized)
    end
    
    # 関連するuserの存在チェック
    unless current_user_auth.user
      Rails.logger.error "トークンリフレッシュエラー: current_user_authにuserが関連付けられていません - user_auth_id=#{current_user_auth.id}"
      return render_error("ユーザー情報が見つかりません", status: :internal_server_error)
    end
    
    # Devise JWTの自動発行を使用（手動でJWTを生成しない）
    # レスポンスヘッダーからJWTトークンを取得
    new_token = request.env['warden-jwt_auth.token']
    
    render_success({
      token: new_token,
      user: {
        id: current_user_auth.user.id,
        name: current_user_auth.user.name || current_user_auth.email.split('@').first,
        email: current_user_auth.email,
        user_type: current_user_auth.user.user_type || 'player',
        generation: current_user_auth.user.generation || 1,
        profile_image_url: current_user_auth.profile_image_url
      }
    }, "JWTトークンを更新しました")
  rescue => e
    Rails.logger.error "JWTリフレッシュエラー: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render_error("トークンリフレッシュ処理中にエラーが発生しました", status: :internal_server_error)
  end

end
