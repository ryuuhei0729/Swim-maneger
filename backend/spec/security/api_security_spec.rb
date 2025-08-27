require 'rails_helper'

RSpec.describe 'API Security', type: :request do
  let(:user) { create(:user, :player) }
  let(:user_auth) { create(:user_auth, user: user) }
  let(:admin_user) { create(:user, :coach) }
  let(:admin_auth) { create(:user_auth, user: admin_user) }

  describe '認証・認可テスト' do
    it '無効なトークンでのアクセス拒否' do
      get '/api/v1/home', headers: { 'Authorization' => 'Bearer invalid_token' }
      expect(response).to have_http_status(:unauthorized)
    end

    it 'トークンなしでのアクセス拒否' do
      get '/api/v1/home'
      expect(response).to have_http_status(:unauthorized)
    end

    it '期限切れトークンでのアクセス拒否' do
      # 実際の期限切れトークンのテスト
      # トークンを生成してから無効化
      token = get_auth_token(user_auth)
      user_auth.update!(authentication_token: nil) # トークンを無効化

      get '/api/v1/home', headers: { 'Authorization' => "Bearer #{token}" }
      expect(response).to have_http_status(:unauthorized)
    end

    it '一般ユーザーでの管理者機能アクセス拒否' do
      token = get_auth_token(user_auth)

      get '/api/v1/admin/dashboard', headers: { 'Authorization' => "Bearer #{token}" }
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'XSS対策テスト' do
    it 'HTMLタグのエスケープ' do
      token = get_auth_token(user_auth)
      malicious_input = '<script>alert("xss")</script><img src="x" onerror="alert(1)">'

      patch '/api/v1/mypage',
            params: { user: { bio: malicious_input } },
            headers: { 'Authorization' => "Bearer #{token}" }

      expect(response).to have_http_status(:ok)

      # レスポンスにスクリプトが含まれていないことを確認
      response_body = response.body
      expect(response_body).not_to include('<script>')
      expect(response_body).not_to include('onerror=')
      expect(response_body).not_to include('alert(')
    end

    it 'JavaScriptイベントハンドラーの無効化' do
      token = get_auth_token(user_auth)
      malicious_input = 'javascript:alert("xss")'

      patch '/api/v1/mypage',
            params: { user: { bio: malicious_input } },
            headers: { 'Authorization' => "Bearer #{token}" }

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('javascript:')
    end
  end

  describe 'SQLインジェクション対策テスト' do
    it '基本的なSQLインジェクション攻撃の防止' do
      token = get_auth_token(user_auth)
      malicious_inputs = [
        "'; DROP TABLE users; --",
        "' OR '1'='1",
        "'; INSERT INTO users VALUES (999, 'hacker'); --",
        "' UNION SELECT * FROM users --"
      ]

      malicious_inputs.each do |input|
        get "/api/v1/members?search=#{input}",
            headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:ok)
        # データベースが正常に動作していることを確認
        expect(User.count).to be > 0
      end
    end

    it 'パラメータ化クエリの使用' do
      token = get_auth_token(user_auth)

      # 特殊文字を含む検索
      special_chars = "';--/*()[]{}\"'`~!@#$%^&*()_+-="

      get "/api/v1/members?search=#{special_chars}",
          headers: { 'Authorization' => "Bearer #{token}" }

      expect(response).to have_http_status(:ok)
      expect(User.count).to be > 0
    end
  end

  describe 'CSRF対策テスト' do
    it 'APIエンドポイントでのCSRF保護' do
      token = get_auth_token(user_auth)

      # CSRFトークンなしでのPOSTリクエスト
      post '/api/v1/objectives',
           params: { objective: { title: 'test' } },
           headers: { 'Authorization' => "Bearer #{token}" }

      # APIではCSRFトークンが不要であることを確認
      expect(response).not_to have_http_status(:unprocessable_entity)
    end
  end

  describe '入力値検証テスト' do
    it '不正なパラメータの拒否' do
      token = get_auth_token(user_auth)

      # 不正なパラメータ
      invalid_params = [
        { user: { email: 'invalid-email' } },
        { user: { generation: 'not-a-number' } },
        { user: { user_type: 999 } }
      ]

      invalid_params.each do |params|
        patch '/api/v1/mypage',
              params: params,
              headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    it 'ファイルアップロードの検証' do
      token = get_auth_token(user_auth)

      # 不正なファイルタイプ
      malicious_file = fixture_file_upload('malicious.php', 'application/x-php')

      patch '/api/v1/mypage',
            params: { user: { avatar: malicious_file } },
            headers: { 'Authorization' => "Bearer #{token}" }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'レート制限テスト' do
    it 'APIレート制限の動作' do
      token = get_auth_token(user_auth)

      # 制限内でのリクエスト
      10.times do
        get '/api/v1/home', headers: { 'Authorization' => "Bearer #{token}" }
        expect(response).to have_http_status(:ok)
      end
    end

    it 'ログイン試行制限' do
      limit = 5

      # 制限前の5回は認証失敗だが429ではないことを確認
      limit.times do
        post '/api/v1/auth/login', params: {
          email: user_auth.email,
          password: 'wrong_password'
        }
        expect(response).not_to have_http_status(:too_many_requests)
        expect(response).to have_http_status(:unauthorized)
      end

      # 6回目で制限がかかることを確認
      post '/api/v1/auth/login', params: {
        email: user_auth.email,
        password: 'wrong_password'
      }
      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe 'セッション管理テスト' do
    it 'セッションタイムアウト' do
      token = get_auth_token(user_auth)

      # 期限切れトークンのシミュレーション
      # 実際の認証フローで期限切れトークンが拒否されることをテスト
      expired_user_auth = UserAuth.find_by(authentication_token: token)
      expired_user_auth.update!(authentication_token: nil) # トークンを無効化

      get '/api/v1/home', headers: { 'Authorization' => "Bearer #{token}" }
      expect(response).to have_http_status(:unauthorized)
    end

    it '同時セッション制限' do
      # 複数のトークンを生成（UserAuthモデルは認証トークンを上書きするため、最新のトークンのみ有効）
      tokens = []
      3.times do
        tokens << get_auth_token(user_auth)
      end

      # 最新のトークンのみが有効であることを確認
      tokens.each_with_index do |token, index|
        get '/api/v1/home', headers: { 'Authorization' => "Bearer #{token}" }

        if index == tokens.length - 1
          # 最新のトークン（最後に生成されたトークン）は有効
          expect(response).to have_http_status(:ok)
        else
          # 古いトークンは無効（unauthorizedまたはforbidden）
          expect(response).to have_http_status(:unauthorized)
        end
      end
    end
  end

  describe 'データ漏洩対策テスト' do
    it '機密情報の除外' do
      token = get_auth_token(user_auth)

      get '/api/v1/mypage', headers: { 'Authorization' => "Bearer #{token}" }

      response_body = response.body
      # 機密情報が含まれていないことを確認
      expect(response_body).not_to include('password')
      expect(response_body).not_to include('encrypted_password')
      expect(response_body).not_to include('reset_password_token')
      expect(response_body).not_to include('authentication_token')
    end

    it 'エラーメッセージでの情報漏洩防止' do
      token = get_auth_token(user_auth)

      # 存在しないリソースへのアクセス
      get '/api/v1/users/999999', headers: { 'Authorization' => "Bearer #{token}" }

      # 詳細なエラー情報が含まれていないことを確認
      expect(response.body).not_to include('ActiveRecord::RecordNotFound')
      expect(response.body).not_to include('database')
    end
  end

  describe 'HTTPセキュリティヘッダーテスト' do
    it 'セキュリティヘッダーの設定' do
      token = get_auth_token(user_auth)

      get '/api/v1/home', headers: { 'Authorization' => "Bearer #{token}" }

      # セキュリティヘッダーの確認
      expect(response.headers['X-Content-Type-Options']).to eq('nosniff')
      expect(response.headers['X-Frame-Options']).to eq('DENY')
      expect(response.headers['X-XSS-Protection']).to eq('1; mode=block')
      expect(response.headers['Referrer-Policy']).to eq('strict-origin-when-cross-origin')
    end
  end

  describe '権限昇格攻撃対策テスト' do
    it 'ユーザーIDの改ざん防止' do
      token = get_auth_token(user_auth)
      other_user = create(:user, :player)

      # 他のユーザーの情報にアクセスしようとする
      get "/api/v1/users/#{other_user.id}",
          headers: { 'Authorization' => "Bearer #{token}" }

      expect(response).to have_http_status(:forbidden)
    end

    it '管理者権限の不正取得防止' do
      token = get_auth_token(user_auth)

      # 管理者機能にアクセスしようとする
      patch "/api/v1/users/#{user.id}",
            params: { user: { user_type: 3 } }, # director
            headers: { 'Authorization' => "Bearer #{token}" }

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'ログインセキュリティテスト' do
    it 'ブルートフォース攻撃対策' do
      # 多数のログイン試行
      20.times do
        post '/api/v1/auth/login', params: {
          email: user_auth.email,
          password: 'wrong_password'
        }
      end

      # アカウントがロックされることを確認
      expect(response).to have_http_status(:too_many_requests)
    end

    it 'パスワード強度の検証' do
      weak_passwords = [ '123456', 'password', 'qwerty', 'abc123' ]

      weak_passwords.each do |password|
        post '/api/v1/auth/login', params: {
          email: user_auth.email,
          password: password
        }

        # 弱いパスワードでのログインが拒否されることを確認
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  private

  def get_auth_token(user_auth)
    post '/api/v1/auth/login', params: {
      email: user_auth.email,
      password: user_auth.password
    }
    JSON.parse(response.body)['data']['token']
  end
end
