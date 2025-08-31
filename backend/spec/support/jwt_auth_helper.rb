module JwtAuthHelper
  def generate_jwt_token(user_auth)
    user_auth.generate_jwt
  end

  def auth_headers(user_auth)
    { 'Authorization' => "Bearer #{generate_jwt_token(user_auth)}" }
  end

  def admin_auth_headers
    admin_user_auth = create(:user_auth, user: create(:user, user_type: :coach))
    auth_headers(admin_user_auth)
  end

  def player_auth_headers
    player_user_auth = create(:user_auth, user: create(:user, user_type: :player))
    auth_headers(player_user_auth)
  end
end

RSpec.configure do |config|
  config.include JwtAuthHelper, type: :request
end
