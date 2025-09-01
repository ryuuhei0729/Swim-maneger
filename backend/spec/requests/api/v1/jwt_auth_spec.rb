require 'rails_helper'

RSpec.describe 'Api::V1::JwtAuth', type: :request do
  let(:user) { create(:user, user_type: :player) }
  let(:user_auth) { create(:user_auth, user: user, email: 'test@example.com', password: 'password123') }

  # テスト前にユーザーを作成
  before do
    user_auth # letで定義したuser_authを実際に作成
  end

  describe 'POST /api/v1/jwt_auth/login' do
    context '有効な認証情報の場合' do
      it 'JWTトークンを返す' do
        post '/api/v1/jwt_auth/login', params: {
          email: user_auth.email,
          password: 'password123'
        }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        
        expect(json['success']).to be true
        expect(json['data']['token']).to be_present
        expect(json['data']['user']['id']).to eq(user.id)
        expect(json['data']['user']['email']).to eq(user_auth.email)
        expect(json['data']['user']['user_type']).to eq('player')
      end
    end

    context '無効な認証情報の場合' do
      it 'エラーを返す' do
        post '/api/v1/jwt_auth/login', params: {
          email: user_auth.email,
          password: 'wrongpassword'
        }

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        
        expect(json['success']).to be false
        expect(json['message']).to eq('メールアドレスまたはパスワードが間違っています')
      end
    end
  end

  describe 'DELETE /api/v1/jwt_auth/logout' do
    it 'ログアウトに成功する' do
      # まずログインしてトークンを取得
      post '/api/v1/jwt_auth/login', params: {
        email: user_auth.email,
        password: 'password123'
      }
      jwt_token = JSON.parse(response.body)['data']['token']

      # ログアウト
      delete '/api/v1/jwt_auth/logout', headers: {
        'Authorization' => "Bearer #{jwt_token}"
      }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      
      expect(json['success']).to be true
      expect(json['message']).to eq('JWTログアウトしました')
    end
  end

  describe 'POST /api/v1/jwt_auth/refresh' do
    it '新しいJWTトークンを返す' do
      # まずログインしてトークンを取得
      post '/api/v1/jwt_auth/login', params: {
        email: user_auth.email,
        password: 'password123'
      }
      jwt_token = JSON.parse(response.body)['data']['token']

      # リフレッシュ
      post '/api/v1/jwt_auth/refresh', headers: {
        'Authorization' => "Bearer #{jwt_token}"
      }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      
      expect(json['success']).to be true
      expect(json['data']['token']).to be_present
      expect(json['data']['user']['id']).to eq(user.id)
      
      # 新しいトークンが元のトークンと異なることを確認
      new_token = json['data']['token']
      expect(new_token).not_to eq(jwt_token)
    end
  end

  describe 'JWT認証の統合テスト' do
    it 'JWTトークンで他のAPIにアクセスできる' do
      # まずログインしてトークンを取得
      post '/api/v1/jwt_auth/login', params: {
        email: user_auth.email,
        password: 'password123'
      }
      jwt_token = JSON.parse(response.body)['data']['token']

      # 他のAPIにアクセス
      get '/api/v1/home', headers: {
        'Authorization' => "Bearer #{jwt_token}"
      }

      expect(response).to have_http_status(:ok)
    end

    it '無効なJWTトークンではアクセスできない' do
      get '/api/v1/home', headers: {
        'Authorization' => 'Bearer invalid_token'
      }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
