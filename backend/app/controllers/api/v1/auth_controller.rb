class Api::V1::AuthController < Api::V1::BaseController
  skip_before_action :authenticate_api_user!, only: [:login]

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
      }, "ログインに成功しました")
    else
      render_error("メールアドレスまたはパスワードが間違っています", status: :unauthorized)
    end
  end

  def logout
    if current_user_auth
      # JWTトークンを無効化
      current_user_auth.revoke_jwt(request.headers['Authorization'])
      render_success({}, "ログアウトしました")
    else
      render_error("ログイン状態ではありません", status: :unauthorized)
    end
  end
end 