require 'rails_helper'

RSpec.describe 'Api::V1::JwtAuth', type: :request do
  let(:user) { create(:user, user_type: :player) }
  let(:user_auth) { create(:user_auth, user: user, email: 'test@example.com', password: 'password123') }

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
    let(:jwt_token) do
      post '/api/v1/jwt_auth/login', params: {
        email: user_auth.email,
        password: 'password123'
      }
      JSON.parse(response.body)['data']['token']
    end

    it 'ログアウトに成功する' do
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
    let(:jwt_token) do
      post '/api/v1/jwt_auth/login', params: {
        email: user_auth.email,
        password: 'password123'
      }
      JSON.parse(response.body)['data']['token']
    end

    it '新しいJWTトークンを返す' do
      post '/api/v1/jwt_auth/refresh', headers: {
        'Authorization' => "Bearer #{jwt_token}"
      }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      
      expect(json['success']).to be true
      expect(json['data']['token']).to be_present

      expect(json['data']['user']['id']).to eq(user.id)
      
      # 新しいトークンが有効であることを確認
      new_token = json['data']['token']
      # テスト環境用のJWT検証メソッドを使用
      decoded_token = decode_jwt_token(new_token)
      expect(decoded_token['sub'].to_i).to eq(user_auth.id)
    end
  end

  describe 'JWT認証の統合テスト' do
    let(:jwt_token) do
      post '/api/v1/jwt_auth/login', params: {
        email: user_auth.email,
        password: 'password123'
      }
      JSON.parse(response.body)['data']['token']
    end

    it 'JWTトークンで他のAPIにアクセスできる' do
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
