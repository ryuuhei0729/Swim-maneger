require 'rails_helper'

RSpec.describe 'API Performance', type: [:performance, :request] do
  let(:user) { create(:user, :player) }
  let(:user_auth) { create(:user_auth, user: user) }
  let(:admin_user) { create(:user, :coach) }
  let(:admin_auth) { create(:user_auth, user: admin_user) }

  # キャッシュ設定の管理
  around do |example|
    # 元の設定を保存
    original_perform_caching = Rails.application.config.action_controller.perform_caching
    original_cache_store = Rails.cache
    
    begin
      # テスト用のキャッシュ設定を有効化
      Rails.application.config.action_controller.perform_caching = true
      Rails.cache = ActiveSupport::Cache::MemoryStore.new
      
      # テストを実行
      example.run
    ensure
      # 元の設定を復元
      Rails.application.config.action_controller.perform_caching = original_perform_caching
      Rails.cache = original_cache_store
    end
  end

  # Rack::Attackのレート制限を無効化（レート制限テスト用）
  around(:each, :rate_limit_test) do |example|
    # 元のRack::Attack設定を保存
    original_rack_attack_enabled = Rack::Attack.enabled?
    
    begin
      # Rack::Attackを無効化
      Rack::Attack.enabled = false
      
      # テストを実行
      example.run
    ensure
      # 元の設定を復元
      Rack::Attack.enabled = original_rack_attack_enabled
    end
  end

  before do
    # テストデータの準備
    create_list(:user, 100, :player)
    create_list(:event, 50, :practice)
    create_list(:event, 20, :competition)
    create_list(:announcement, 30)
  end

  describe 'レスポンス時間テスト' do
    it 'ホーム画面のレスポンス時間' do
      token = get_auth_token(user_auth)
      
      expect {
        get '/api/v1/home', headers: { 'Authorization' => "Bearer #{token}" }
      }.to perform_under(500).ms
    end

    it 'メンバー一覧のレスポンス時間' do
      token = get_auth_token(user_auth)
      
      expect {
        get '/api/v1/members', headers: { 'Authorization' => "Bearer #{token}" }
      }.to perform_under(300).ms
    end

    it '管理者ダッシュボードのレスポンス時間' do
      token = get_auth_token(admin_auth)
      
      expect {
        get '/api/v1/admin/dashboard', headers: { 'Authorization' => "Bearer #{token}" }
      }.to perform_under(1000).ms
    end

    it 'カレンダーのレスポンス時間' do
      token = get_auth_token(user_auth)
      
      expect {
        get '/api/v1/calendar', headers: { 'Authorization' => "Bearer #{token}" }
      }.to perform_under(400).ms
    end
  end

  describe 'データベースクエリ最適化テスト' do
    it 'N+1問題の回避' do
      token = get_auth_token(user_auth)
      
      # クエリ数の測定
      expect {
        get '/api/v1/members', headers: { 'Authorization' => "Bearer #{token}" }
      }.to make_database_queries(count: be_between(1, 5))
    end

    it '関連データを含むクエリの最適化' do
      token = get_auth_token(user_auth)
      
      expect {
        get '/api/v1/calendar', headers: { 'Authorization' => "Bearer #{token}" }
      }.to make_database_queries(count: be_between(1, 3))
    end
  end

  describe 'メモリ使用量テスト' do
    it '大量データでのメモリ使用量' do
      token = get_auth_token(user_auth)
      
      expect {
        get '/api/v1/members', headers: { 'Authorization' => "Bearer #{token}" }
      }.to allocate_under(50).mb
    end

    it '複雑なクエリでのメモリ使用量' do
      token = get_auth_token(admin_auth)
      
      expect {
        get '/api/v1/admin/dashboard', headers: { 'Authorization' => "Bearer #{token}" }
      }.to allocate_under(100).mb
    end
  end

  describe '同時アクセステスト' do
    it '複数ユーザーからの同時アクセス' do
      tokens = []
      5.times do
        user = create(:user, :player)
        auth = create(:user_auth, user: user)
        tokens << get_auth_token(auth)
      end

      # 各スレッドで独立したRack::MockRequestインスタンスを使用
      threads = tokens.map do |token|
        Thread.new do
          mock_request = Rack::MockRequest.new(Rails.application)
          response = mock_request.get('/api/v1/home', {
            'HTTP_AUTHORIZATION' => "Bearer #{token}"
          })
          response
        end
      end

      threads.each(&:join)
      
      # 全てのレスポンスが成功することを確認
      threads.each do |thread|
        expect(thread.value.status).to eq(200)
      end
    end
  end

  describe 'キャッシュ効果テスト' do
    it 'キャッシュヒット時のパフォーマンス向上' do
      token = get_auth_token(user_auth)
      
      # 初回アクセス（キャッシュミス）
      first_response_time = measure_response_time do
        get '/api/v1/members', headers: { 'Authorization' => "Bearer #{token}" }
      end

      # 2回目のアクセス（キャッシュヒット）
      second_response_time = measure_response_time do
        get '/api/v1/members', headers: { 'Authorization' => "Bearer #{token}" }
      end

      # キャッシュヒット時の方が高速であることを確認
      expect(second_response_time).to be < first_response_time
    end
  end

  describe '大量データ処理テスト' do
    it '大量ユーザーでの検索パフォーマンス' do
      # 大量のユーザーデータを作成
      create_list(:user, 1000, :player)
      token = get_auth_token(admin_auth)
      
      expect {
        get '/api/v1/admin/users', headers: { 'Authorization' => "Bearer #{token}" }
      }.to perform_under(2000).ms
    end

    it '大量イベントでのカレンダー表示' do
      # 大量のイベントデータを作成
      create_list(:event, 500, :practice)
      token = get_auth_token(user_auth)
      
      expect {
        get '/api/v1/calendar', headers: { 'Authorization' => "Bearer #{token}" }
      }.to perform_under(1000).ms
    end
  end

  describe 'API Rate Limiting パフォーマンス' do
    it 'レート制限下でのパフォーマンス', :rate_limit_test do
      token = get_auth_token(user_auth)
      
      # 制限内での連続リクエスト
      response_times = []
      10.times do
        response_time = measure_response_time do
          get '/api/v1/home', headers: { 'Authorization' => "Bearer #{token}" }
        end
        response_times << response_time
      end

      # 平均レスポンス時間が許容範囲内であることを確認
      average_response_time = response_times.sum / response_times.length
      expect(average_response_time).to be < 500
    end
  end

  describe 'JSON レスポンスサイズテスト' do
    it 'レスポンスサイズの最適化' do
      token = get_auth_token(user_auth)
      
      get '/api/v1/members', headers: { 'Authorization' => "Bearer #{token}" }
      
      # レスポンスサイズが適切な範囲内であることを確認
      response_size = response.body.bytesize
      expect(response_size).to be < 100_000 # 100KB以下
    end

    it '不要なデータの除外' do
      token = get_auth_token(user_auth)
      
      get '/api/v1/mypage', headers: { 'Authorization' => "Bearer #{token}" }
      
      # パスワードなどの機密情報が含まれていないことを確認
      expect(response.body).not_to include('password')
      expect(response.body).not_to include('encrypted_password')
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

  def measure_response_time
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    yield
    end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    (end_time - start_time) * 1000.0 # ミリ秒単位で返す（浮動小数点）
  end
end
