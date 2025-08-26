require 'rails_helper'

RSpec.describe 'API V1 Integration', type: :request do
  let(:user) { create(:user, :player) }
  let(:user_auth) { create(:user_auth, user: user) }
  let(:admin_user) { create(:user, :coach) }
  let(:admin_auth) { create(:user_auth, user: admin_user) }

  describe '認証フロー' do
    it 'ログインからAPI利用までの一連の流れ' do
      # 1. ログイン
      post '/api/v1/auth/login', params: {
        email: user_auth.email,
        password: user_auth.password
      }
      expect(response).to have_http_status(:ok)
      token = JSON.parse(response.body)['data']['token']

      # 2. トークンを使用してAPIアクセス
      get '/api/v1/home', headers: { 'Authorization' => "Bearer #{token}" }
      expect(response).to have_http_status(:ok)

      # 3. ログアウト
      delete '/api/v1/auth/logout', headers: { 'Authorization' => "Bearer #{token}" }
      expect(response).to have_http_status(:ok)
    end

    it '無効なトークンでのアクセス拒否' do
      get '/api/v1/home', headers: { 'Authorization' => 'Bearer invalid_token' }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe '管理者権限チェック' do
    it '一般ユーザーでの管理者機能アクセス拒否' do
      token = get_player_token
      get '/api/v1/admin/dashboard', headers: { 'Authorization' => "Bearer #{token}" }
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'エラーハンドリング' do
    let(:token) { get_player_token }

    it '存在しないリソースへのアクセス' do
      get '/api/v1/members/999999', headers: { 'Authorization' => "Bearer #{token}" }
      expect(response).to have_http_status(:not_found)
    end

    it '不正なパラメータでのリクエスト' do
      post '/api/v1/objectives', 
           params: { invalid_param: 'value' },
           headers: { 'Authorization' => "Bearer #{token}" }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'バリデーションエラー' do
      post '/api/v1/objectives', 
           params: { objective: { invalid_field: '' } },
           headers: { 'Authorization' => "Bearer #{token}" }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe 'セキュリティテスト' do
    it 'XSS対策' do
      token = get_player_token
      malicious_input = '<script>alert("xss")</script>'
      
      patch '/api/v1/mypage', 
            params: { user: { bio: malicious_input } },
            headers: { 'Authorization' => "Bearer #{token}" }
      
      expect(response).to have_http_status(:ok)
      
      # レスポンスにスクリプトタグが含まれていないことを確認
      response_body = response.body
      expect(response_body).not_to include('<script>')
      expect(response_body).not_to include('alert("xss")')
    end

    it 'SQLインジェクション対策' do
      token = get_player_token
      malicious_input = "'; DROP TABLE users; --"
      
      get "/api/v1/members?search=#{malicious_input}", 
          headers: { 'Authorization' => "Bearer #{token}" }
      
      expect(response).to have_http_status(:ok)
      # データベースが正常に動作していることを確認
      expect(User.count).to be > 0
    end
  end

  describe 'レート制限テスト' do
    it 'APIレート制限の動作' do
      token = get_player_token
      
      # 短時間で多数のリクエストを送信
      10.times do
        get '/api/v1/home', headers: { 'Authorization' => "Bearer #{token}" }
      end
      
      # 最後のリクエストが成功することを確認（制限内）
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'HTTPセキュリティヘッダーテスト' do
    it 'セキュリティヘッダーの設定' do
      token = get_player_token
      
      get '/api/v1/home', headers: { 'Authorization' => "Bearer #{token}" }
      
      # セキュリティヘッダーの確認
      expect(response.headers['X-Content-Type-Options']).to eq('nosniff')
      expect(response.headers['X-Frame-Options']).to eq('DENY')
      expect(response.headers['X-XSS-Protection']).to eq('1; mode=block')
      expect(response.headers['Referrer-Policy']).to eq('strict-origin-when-cross-origin')
    end
  end

  private

  def get_player_token
    post '/api/v1/auth/login', params: {
      email: user_auth.email,
      password: user_auth.password
    }
    JSON.parse(response.body)['data']['token']
  end
end
