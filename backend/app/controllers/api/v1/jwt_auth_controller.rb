class Api::V1::JwtAuthController < Api::V1::BaseController
  skip_before_action :authenticate_user_auth!, only: [:login]

  def login
    user_auth = UserAuth.find_by(email: params[:email])
    
    if user_auth&.valid_password?(params[:password])
      # JWTトークンを生成
      jwt_token = user_auth.generate_jwt
      
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
      }, "JWTログインに成功しました")
    else
      render_error("メールアドレスまたはパスワードが間違っています", status: :unauthorized)
    end
  end

  def logout
    if current_user_auth
      # JWTトークンを無効化
      current_user_auth.revoke_jwt(request.headers['Authorization'])
      render_success({}, "JWTログアウトしました")
    else
      render_error("ログイン状態ではありません", status: :unauthorized)
    end
  end

  def refresh
    # JWTトークンのリフレッシュ
    if current_user_auth
      # 新しい有効期限でトークンを生成
      new_token = JWT.encode(
        {
          user_id: current_user_auth.id,
          email: current_user_auth.email,
          exp: 24.hours.from_now.to_i
        },
        ENV['JWT_SECRET_KEY'] || Rails.application.secret_key_base,
        'HS256'
      )
      
      render_success({
        token: new_token,
        user: {
          id: current_user_auth.user.id,
          name: current_user_auth.user.name,
          email: current_user_auth.email,
          user_type: current_user_auth.user.user_type,
          generation: current_user_auth.user.generation,
          profile_image_url: current_user_auth.profile_image_url
        }
      }, "JWTトークンを更新しました")
    else
      render_error("有効なトークンがありません", status: :unauthorized)
    end
  end
end
